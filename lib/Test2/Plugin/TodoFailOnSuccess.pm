package Test2::Plugin::TodoFailOnSuccess;

use strict;
use warnings;

# ABSTRACT: Report failure if a TODO test unexpectedly passes
# VERSION

our $AUTHORITY = 'cpan:GSG';

=encoding utf8

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Provides a mechanism to report test failures when TODO tests unexpectedly pass.

If a TODO test passes, a failure will be reported with a message containing
both the test description and the TODO reason, equivalent to doing:

  fail "TODO passed unexpectedly: $test_description # $todo_reason";

For example:

  TODO passed unexpectedly: Got expected value # TODO Not expected to pass

There are no options or arguments, just C<use Test2::Plugin::TodoFailOnSuccess>
in your test file.

=cut

use Test2::API qw(
    test2_add_callback_context_init
    test2_add_callback_context_release
);

my $PLUGIN_LOADED = 0;

sub import
{
    return if $PLUGIN_LOADED++;

    test2_add_callback_context_init   ( \&on_context_init    );
    test2_add_callback_context_release( \&on_context_release );
}

sub on_context_init
{
    my ($ctx) = @_;

    # Set up a listener on the hub to watch events going by,
    # looking for the ones that indicate a TODO test which passed:
    #
    $ctx->{_TodoFailOnSuccess_hub_listener} = $ctx->hub->listen(
        sub {
            my ($hub, $event, $number) = @_;

            my $facet_data = $event->facet_data;

            # Events inside a TODO will have amnesty (although will
            # need to verify the type of amnesty later):
            #
            my $amnesty_list = $facet_data->{amnesty};
            return unless $amnesty_list && @$amnesty_list;

            # Only interested if the event made an assertion which passed:
            #
            my $assert = $facet_data->{assert};
            return unless $assert && $assert->{pass};

            # Make sure at least one of the amnesty reasons
            # is because of TODO:
            #
            my %todo_reasons;
            foreach my $amnesty (@$amnesty_list) {
                next unless $amnesty->{tag} eq 'TODO';
                $todo_reasons{ $amnesty->{details} } = 1;
            }
            return unless keys %todo_reasons;

            my $details = $assert->{details};

            foreach my $todo_reason (sort keys %todo_reasons) {
                $ctx->fail(
                    qq{TODO passed unexpectedly: $details # TODO $todo_reason}
                );
            }
        },
        inherit => 1,
    );
}

sub on_context_release
{
    my ($ctx) = @_;

    my $hub_listener = delete $ctx->{_TodoFailOnSuccess_hub_listener};
    $ctx->hub->unlisten($hub_listener) if $hub_listener;
}

1;

