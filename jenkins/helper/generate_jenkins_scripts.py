#!/bin/env python3
""" read test definition, and generate the output for the specified target """
import argparse
import sys

#pylint: disable=line-too-long disable=broad-except

# check python 3
if sys.version_info[0] != 3:
    print("found python version ", sys.version_info)
    sys.exit()


def generate_fish_output(args, outfile, tests):
    """ unix/fish conformant test definitions """
    def output(line):
        """ output one line """
        print(line, file=outfile)

    def print_test_func(test, func, varname):
        """ print one test function """
        args = " ".join(test["args"])
        params = test["params"]
        suffix = params.get("suffix", "-")

        conditions = []
        if "enterprise" in test["flags"]:
            conditions.append("isENTERPRISE;")
        if "ldap" in test["flags"]:
            conditions.append("hasLDAPHOST;")

        if len(conditions) > 0:
            conditions_string = " and ".join(conditions) + " and "
        else:
            conditions_string = ""

        if "buckets" in params:
            num_buckets = int(params["buckets"])
            for i in range(num_buckets):
                output(
                    f'{conditions_string}'
                    f'set {varname} "${varname}""{test["weight"]},{func} \'{test["name"]}\''
                    f' {i} --testBuckets {num_buckets}/{i} {args}\\n"')
        else:
            output(f'{conditions_string}'
                   f'set {varname} "${varname}""{test["weight"]},{func} \'{test["name"]}\' '
                   f'{suffix} {args}\\n"')

    def print_all_tests(func, varname):
        """ iterate over all definitions """
        for test in tests:
            print_test_func(test, func, varname)

    if args.cluster:
        print_all_tests("runClusterTest1", "CT")
    else:
        print_all_tests("runSingleTest1", "ST")


def generate_ps1_output(args, outfile, tests):
    """ powershell conformant test definitions """
    def output(line):
        """ output one line """
        print(line, file=outfile)

    for test in tests:
        params = test["params"]
        suffix = f' -index "{params["suffix"]}"' if "suffix" in params else ""
        cluster_str = " -cluster $true" if args.cluster else ""
        condition_prefix = ""
        condition_suffix = ""
        if "enterprise" in test["flags"]:
            condition_prefix = 'If ($ENTERPRISEEDITION -eq "On") { '
            condition_suffix = ' }'
        if "ldap" in test["flags"]:
            raise Exception("ldap not supported for windows")

        moreargs = ""
        args_list = test["args"]
        if len(args_list) > 0:
            moreargs = f' -moreParams "{" ".join(args_list)}"'

        if "buckets" in params:
            num_buckets = int(params["buckets"])
            for i in range(num_buckets):
                output(f'{condition_prefix}'
                       f'registerTest -testname "{test["name"]}" -weight {test["wweight"]} '
                       f'-index "{i}" -bucket "{num_buckets}/{i}"{moreargs}{cluster_str}'
                       f'{condition_suffix}')
        else:
            output(f'{condition_prefix}'
                   f'registerTest -testname "{test["name"]}"{cluster_str} -weight {test["wweight"]}{suffix}{moreargs}'
                   f'{condition_suffix}')


def filter_tests(args, tests):
    """ filter testcase by operations target Single/Cluster/full """
    if args.all:
        return tests

    filters = []
    if args.cluster:
        filters.append(lambda test: "single" not in test["flags"])
    else:
        filters.append(lambda test: "cluster" not in test["flags"])

    if args.full:
        filters.append(lambda test: "!full" not in test["flags"])
    else:
        filters.append(lambda test: "full" not in test["flags"])

    if args.format == "ps1":
        filters.append(lambda test: "!windows" not in test["flags"])

    for one_filter in filters:
        tests = filter(one_filter, tests)
    return list(tests)


def generate_dump_output(_, outfile, tests):
    """ interactive version output to inspect comprehension """
    def output(line):
        """ output one line """
        print(line, file=outfile)

    for test in tests:
        params = " ".join(f"{key}={value}" for key, value in test['params'].items())
        output(f"{test['name']}")
        output(f"\tweight: {test['weight']}")
        output(f"\tweight: {test['wweight']}")
        output(f"\tflags: {' '.join(test['flags'])}")
        output(f"\tparams: {params}")
        output(f"\targs: {' '.join(test['args'])}")


formats = {
    "dump": generate_dump_output,
    "fish": generate_fish_output,
    "ps1": generate_ps1_output,
}

known_flags = {
    "cluster": "this test requires a cluster",
    "single": "this test requires a single server",
    "full": "this test is only executed in full tests",
    "!full": "this test is only executed in non-full tests",
    "ldap": "ldap",
    "enterprise": "this tests is only executed with the enterprise version",
    "!windows": "test is excluded from ps1 output"
}

known_parameter = {
    "buckets": "number of buckets to use for this test",
    "suffix": "suffix that is appended to the tests folder name",
    "weight": "weight that controls execution order on Linux / Mac. Lower weights are executed later",
    "wweight": "windows weight how many resources will the job use in the SUT? Default: 1 in Single server, 4 in Clusters"
}


def print_help_flags():
    """ print help for flags """
    print("Flags are specified as a single token.")
    for flag, exp in known_flags.items():
        print(f"{flag}: {exp}")

    print("Parameter have a value and specified as param=value.")
    for flag, exp in known_parameter.items():
        print(f"{flag}: {exp}")


def parse_arguments():
    """ argv """
    if "--help-flags" in sys.argv:
        print_help_flags()
        sys.exit()

    parser = argparse.ArgumentParser()
    parser.add_argument("definitions", help="file containing the test definitions", type=str)
    parser.add_argument("-f", "--format", type=str, choices=formats.keys(), help="which format to output",
                        default="fish")
    parser.add_argument("-o", "--output", type=str, help="output file, default is '-', which means stdout", default="-")
    parser.add_argument("--validate-only", help="validates the test definition file", action="store_true")
    parser.add_argument("--help-flags", help="prints information about available flags and exits", action="store_true")
    parser.add_argument("--cluster", help="output only cluster tests instead of single server", action="store_true")
    parser.add_argument("--full", help="output full test set", action="store_true")
    parser.add_argument("--all", help="output all test, ignore other filters", action="store_true")
    args = parser.parse_args()

    return args


def validate_params(params, is_cluster):
    """ check for argument validity """
    def parse_number(value):
        """ check value """
        try:
            return int(value)
        except Exception as exc:
            raise Exception(f"invalid numeric value: {value}") from exc

    def parse_number_or_default(key, default_value=None):
        """ check number """
        if key in params:
            params[key] = parse_number(params[key])
        elif default_value is not None:
            params[key] = default_value

    parse_number_or_default("weight", 250)
    parse_number_or_default("wweight", 4 if is_cluster else 1)
    parse_number_or_default("buckets")

    return params


def validate_flags(flags):
    """ check whether target flags are valid """
    if "cluster" in flags and "single" in flags:
        raise Exception("`cluster` and `single` specified for the same test")
    if "full" in flags and "!full" in flags:
        raise Exception("`full` and `!full` specified for the same test")


def read_definition_line(line):
    """ parse one test definition line """
    bits = line.split()
    if len(bits) < 1:
        raise Exception("expected at least one argument: <testname>")
    name, *remainder = bits

    flags = []
    params = {}
    args = []

    for idx, bit in enumerate(remainder):
        if bit == "--":
            args = remainder[idx + 1:]
            break

        if "=" in bit:
            key, value = bit.split("=", maxsplit=1)
            params[key] = value
        else:
            flags.append(bit)

    # check all flags
    for flag in flags:
        if flag not in known_flags:
            raise Exception(f"Unknown flag `{flag}`")

    # check all params
    for param in params:
        if param not in known_parameter:
            raise Exception(f"Unknown parameter `{param}`")

    validate_flags(flags)
    params = validate_params(params, 'cluster' in flags)

    return {
        "name": name,
        "weight": params["weight"],
        "wweight": params["wweight"],
        "flags": flags,
        "args": args,
        "params": params
    }


def read_definitions(filename):
    """ read test definitions txt """
    tests = []
    has_error = False
    with open(filename, "r", encoding="utf-8") as filep:
        for line_no, line in enumerate(filep):
            line = line.strip()
            if line.startswith("#") or len(line) == 0:
                continue  # ignore comments
            try:
                test = read_definition_line(line)
                tests.append(test)
            except Exception as exc:
                print(f"{filename}:{line_no + 1}: {exc}", file=sys.stderr)
                has_error = True
    if has_error:
        raise Exception("abort due to errors")
    return tests


def generate_output(args, outfile, tests):
    """ generate output """
    if args.format not in formats:
        raise Exception(f"Unknown format `{args.format}`")
    formats[args.format](args, outfile, tests)


def get_output_file(args):
    """ get output file """
    if args.output == '-':
        return sys.stdout
    return open(args.output, "w", encoding="utf-8")


def main():
    """ entrypoint """
    try:
        args = parse_arguments()
        tests = read_definitions(args.definitions)
        if args.validate_only:
            return  # nothing left to do
        tests = filter_tests(args, tests)
        generate_output(args, get_output_file(args), tests)
    except Exception as exc:
        print(exc, file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
