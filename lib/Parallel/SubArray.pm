package Parallel::SubArray;
require 5.008_008;
our $VERSION = 0.1;
use strict;
use Storable qw(store_fd fd_retrieve);
use Exporter 'import';
our @EXPORT_OK = qw(par);

sub par {
  my( $timeout ) = @_;
  sub {
    my $subs = shift;
    my %rets;
    my $c = 0;
    for my $sub ( @$subs ) {
      $c++;
      my( $parent_w, $child_r );
      pipe( $child_r, $parent_w );
      select((select($parent_w ), $| = 1)[0]);
      if( my $pid = fork ) {
	close $parent_w;
	$rets{ $pid } = { fd  => $child_r,
			  ord => $c
			};
      } else {
	die "Cannot fork: $!" unless defined $pid;
	close $child_r;
	local $SIG{ALRM} = sub {
	  close $parent_w;
	  exit 1;
	};
	alarm( $timeout || 0 );
	my $ret = eval{ $sub->() };
	my $error = $@;
	alarm( 0 );
	if( $error ) {
	  warn "$error";
	  $SIG{ALRM}->();
	}
	store_fd $ret, $parent_w;
	close $parent_w;
	exit 0;
      }
    }
    while(1) {
      my $pid = wait();
      last if( $pid == -1 or not @$subs );
      next if not exists $rets{ $pid };
      pop @$subs;
      $rets{ $pid }->{val} = $? ? undef()
	                        : fd_retrieve( $rets{ $pid }->{fd} );
      close $rets{ $pid }->{fd};
    }
    [ map  { $rets{$_}->{val} }
      sort { $rets{$a}->{ord} <=> $rets{$b}->{ord} }
      keys %rets
    ];
  }
}

1;
__END__

=head1 NAME

Parallel::SubArray - Forked sub execution with return values and timeouts.

=head1 SYNOPSIS

  use Parallel::SubArray 'par';

  my $sub_arrayref = [
    sub{ sleep(1); [1] },
    sub{ while(1){}    },
    sub{ [ 1, {2=>3} ] },
  ];

  my $result_arrayref = par(3)->($sub_arrayref);

  $result_arrayref == [
    [ 1 ],
    undef,
    [ 1, { 2 => 3 } ]
  ];

=head1 DESCRIPTION

I want fast, safe, and simple parallelism.  Current offerings did not satisfy me.  Most are not enough while remaining are too complex or tedious.  L<Palallel::SubArray> scratches my itch: forking, joining, timeouts, and return values done simply.

=head1 EXPORT

Nothing.  I don't like magic.

=head1 SEE ALSO

L<perlipc>
L<perlfunc/"fork">
L<perlfork>
L<subs::parallel>
L<Parallel::Simple>
L<Parallel::Queue>
L<Parallel::Forker>
L<Parallel::Jobs>
L<Parallel::Workers>
L<Parallel::SubFork>
L<Parallel::Pvm>
L<Parallel::Performing>
L<Parallel::Fork::BossWorker>
L<Parallel::ForkControl>

=head1 BUGS

Do not use Windows and don't even think of using Object Orientfuscation!  First part of the statement is justified by the lack of forking on that platform while second cannot exist in the parallel world of tomorrow as it requires locking and that defeats the whole purpose.  If you have the itch to ignore the first warning, you will get slower performance (because Perl emulates forking on Windows) and hopefully no bugs.  If you have the OO stones, let me know how you have solved the parallelism problem.  There are millions that will be happy to pay you millions for the answer.

The joining mechanism of this module can be incompatible with other forking because it's waiting for child processes to finish.  Nesting of C<par> works as expected.

Subroutines passed to C<par> that return anything other than references to simple Perl structures may behave unexpectedly.

=head1 AUTHOR

Eugene Grigoriev, intercalate "@" ["eugene.grigoriev", "gmail.com"]

=head1 LICENSE

Copyright (c) 2009, Eugene Grigoriev
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of copyright holder nor the names of contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
