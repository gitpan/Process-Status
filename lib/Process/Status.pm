use strict;
use warnings;
package Process::Status;
{
  $Process::Status::VERSION = '0.002';
}
# ABSTRACT: a handle on process termination, like $?

use Config ();


sub _self { ref $_[0] ? $_[0] : $_[0]->new($?); }

sub new {
  my $pid_t = defined $_[1] ? $_[1] : $?;
  bless \$pid_t, $_[0];
}


sub pid_t {
  ${ $_[0]->_self }
}


sub is_success  { ${ $_[0]->_self } == 0 }


sub exitstatus { ${ $_[0]->_self } >> 8   }


sub signal     { ${ $_[0]->_self } & 127 }


sub cored      { !! (${ $_[0]->_self } & 128) }


sub as_struct {
  my $self = $_[0]->_self;

  my $pid_t = $self->pid_t;

  return {
    pid_t => $pid_t,
    ($pid_t == -1 ? () : (
      exitstatus => $pid_t >> 8,
      cored      => ($pid_t & 128) ? 1 : 0,

      (($pid_t & 127) ? (signal => $pid_t & 127) : ())
    )),
  };
}

my %SIGNAME;
sub __signal_name {
  my ($signal) = @_;
  unless (%SIGNAME) {
    my @names = split /\x20/, $Config::Config{sig_name};
    $SIGNAME{$_} = "SIG$names[$_]" for (1 .. $#names);
  }

  return($SIGNAME{ $signal } || "signal $signal");
}

sub as_string {
  my $self  = $_[0]->_self;
  my $pid_t = $$self;
  my $str  = "exited " . ($pid_t >> 8);
  $str .= ", caught " . __signal_name($pid_t & 127) if $pid_t & 127;
  $str .= "; dumped core" if $pid_t & 128;

  return $str;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Process::Status - a handle on process termination, like $?

=head1 VERSION

version 0.002

=head1 OVERVIEW

When you run a system command with C<system> or C<qx``> or a number of other
mechanisms, the process termination status gets put into C<$?> as an integer.
In C, it's a value of type C<pid_t>, and it stores a few pieces of data in
different bits.

Process::Status just provides a few simple methods to make it easier to
inspect.  Almost the sole reason it exists is for its C<as_struct> method,
which can be passed to a pretty printer to dump C<$?> in a somewhat more
human-readable format.

Methods called on C<Process::Status> without first calling a constructor will
work on an implicitly-constructed object using the current value of C<$?>.  To
get an object for a specific value, you can call C<new> and pass an integer.
You can also call C<new> with no arguments to get an object for the current
value of C<$?>, if you want to keep that ugly variable out of your code.

=head1 METHODS

=head2 new

  my $ps = Process::Status->new( $pid_t );
  my $ps = Process::Status->new; # acts as if you'd passed $?

=head2 pid_t

This returns the value of the C<pid_t> integer, as you might have found in
C<$?>.

=head2 is_success

This method returns true if the C<pid_t> is zero.

=head2 exitstatus

This method returns the exit status of the C<pid_t>.

=head2 signal

This returns the signal caught by the process, or zero.

=head2 cored

This method returns true if the process dumped core.

=head2 as_struct

This method returns a hashref describing the status.  Its exact contents may
change over time; it is meant for human, not computer, consumption.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
