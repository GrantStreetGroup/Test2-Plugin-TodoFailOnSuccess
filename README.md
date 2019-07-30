# NAME

Test2::Plugin::TodoFailOnSuccess - Report failure if a TODO test unexpectedly passes

# VERSION

version 0.0.1

# SYNOPSIS

    package My::Tests;

    use Test2::V0;

    use Test2::Plugin::TodoFailOnSuccess;  # report unexpected TODO success

    use Test2::Tools::Basic;    # for "todo" sub
    use Test2::Todo;            # for "todo" object

    sub test_something
    {
        # Lexical scope TODO:
        #
        {
            my $todo = todo 'Not expected to pass';
            is $value, $expected_value, "Got expected value";
        }

        # Coderef TODO:
        #
        todo 'Not expected to pass either' => sub {
            is $value, $expected_value, "Got expected value";
        };

        # Object-oriented TODO:
        #
        my $todo = Test2::Todo->new( reason => 'Still not expected to pass' );
        is $value, $expected_value, "Got expected value";
        $todo->end;
    }

# DESCRIPTION

Provides a mechanism to report test failures when TODO tests unexpectedly pass.

If a TODO test passes, a failure will be reported with a message containing
both the test description and the TODO reason, equivalent to doing:

    fail "TODO passed unexpectedly: $test_description # $todo_reason";

For example:

    TODO passed unexpectedly: Got expected value # TODO Not expected to pass

There are no options or arguments, just `use Test2::Plugin::TodoFailOnSuccess`
in your test file.

# AUTHOR

Grant Street Group <developers@grantstreet.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Grant Street Group.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

# CONTRIBUTOR

Larry Leszczynski <Larry.Leszczynski@GrantStreet.com>
