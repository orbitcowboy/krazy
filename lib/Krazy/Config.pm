###############################################################################
# Sanity checks for your KDE source code                                      #
# Copyright 2007 by Allen Winter <winter@kde.org>                             #
#                                                                             #
# This program is free software; you can redistribute it and/or modify        #
# it under the terms of the GNU General Public License as published by        #
# the Free Software Foundation; either version 2 of the License, or           #
# (at your option) any later version.                                         #
#                                                                             #
# This program is distributed in the hope that it will be useful,             #
# but WITHOUT ANY WARRANTY; without even the implied warranty of              #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the                #
# GNU General Public License for more details.                                #
#                                                                             #
# You should have received a copy of the GNU General Public License along     #
# with this program; if not, write to the Free Software Foundation, Inc.,     #
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.               #
#                                                                             #
###############################################################################

#TODO:
# handle second args in EXCLUDE, CHECK, EXTRA directives

package Krazy::Config;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
use Cwd;
use Krazy::Utils;

use Exporter;
$VERSION = 1.20;
@ISA = qw(Exporter);

@EXPORT = qw(ParseKrazyRC);
@EXPORT_OK = qw();

#==============================================================================
# .krazy file parsing
#
# Each line in the file can be a control directive, a blank line,
# or a comment. Comment lines start with the # character.
#
# Supports the following directives:
# EXCLUDE plugin1[,plugin2,...] <regexp>
# CHECK plugin1[,plugin2,...] <regexp>
# EXTRA plugin1[,plugin2,...] <regexp>
# SKIP regexp
# PRIORITY <low|normal|high|important|all>
# STRICT <normal|super|all>
# OUTPUT <quiet|brief|normal>
# EXPORT <text|textlist|textedit|xml>
# IGNORESUBS subdir1[,subdir2,...]
# IGNOREMODS module1[,module2,...]
#
# Multiple directives may be specified per file; they will be combined in
# a logical way.
#
# The directive is case-insensitive.
#==============================================================================

my($rcExclude,$rcOnly,$rcExtra,$rcSkipRegex,$rcPriority,$rcStrict,$rcOutput,$rcExport,@rcIgSubsList,@rcIgModsList);
my($CWD);

sub ParseKrazyRC {
  my ($rcfile) = @_;

  my(%directives);
  open( F, "$rcfile" ) || return %directives;

  my ( $line, $linecnt, $directive, $arg );
  $CWD = getcwd;

  $rcExclude    = "";
  $rcOnly       = "";
  $rcExtra      = "";
  $rcSkipRegex  = "";
  $rcPriority   = "";
  $rcStrict     = "";
  $rcOutput     = "";
  $rcExport     = "";
  @rcIgSubsList = ();
  @rcIgModsList = ();

  while ( $line = <F> ) {
    $linecnt++;
    $line =~ s/#.*//;     #strip comment
    $line =~ s/^\s+//;    #strip leading whitespace
    $line =~ s/\s+$//;    #strip trailing whitespace
    next if ( !$line );

    ( $directive, $arg ) = split( " ", $line );
    $directive = uc($directive);
    if ( $directive eq "EXTRA" ) {
      &extras($arg);
    } elsif ( $directive eq "CHECK" ) {
      &checks($arg);
    } elsif ( $directive eq "EXCLUDE" ) {
      &excludes($arg);
    } elsif ( $directive eq "IGNORESUBS" ) {
      &ignoreSubs($arg);
    } elsif ( $directive eq "IGNOREMODS" ) {
      &ignoreMods($arg);
    } elsif ( $directive eq "SKIP" ) {
      &skips($arg);
    } elsif ( $directive eq "PRIORITY" ) {
      &priority($arg);
    } elsif ( $directive eq "STRICT" ) {
      &strict($arg);
    } elsif ( $directive eq "OUTPUT" ) {
      &output($arg);
    } elsif ( $directive eq "EXPORT" ) {
      &export($arg);
    } else {
      print "Invalid directive $directive, line $linecnt, $rcfile... exiting\n";
      close(F);
      exit 1;
    }
  }
  close(F);

  #return a hash of the directives
  $directives{'EXCLUDE'}    = $rcExclude;
  $directives{'CHECK'}      = $rcOnly;
  $directives{'EXTRA'}      = $rcExtra;
  $directives{'SKIPREGEX'}  = $rcSkipRegex;
  $directives{'PRIORITY'}   = $rcPriority;
  $directives{'STRICT'}     = $rcStrict;
  $directives{'OUTPUT'}     = $rcOutput;
  $directives{'EXPORT'}     = $rcExport;
  @{$directives{'IGSUBSLIST'}} = deDupe(@rcIgSubsList);
  @{$directives{'IGMODSLIST'}} = deDupe(@rcIgModsList);
  return %directives;
}

sub extras {
  my ($args) = @_;
  if ( !defined($args) ) {
    print "missing EXTRA arguments in .krazy...exiting\n";
    exit 1;
  }
  if ( !$rcExtra ) {
    $rcExtra = $args;
  } else {
    $rcExtra .= "," . $args;
  }
}

sub checks {
  my ($args) = @_;
  if ( !defined($args) ) {
    print "missing CHECK arguments in .krazy...exiting\n";
    exit 1;
  }
  if ( !$rcOnly ) {
    $rcOnly = $args;
  } else {
    $rcOnly .= "," . $args;
  }
}

sub excludes {
  my ($args) = @_;
  if ( !defined($args) ) {
    print "missing EXCLUDE arguments in .krazy...exiting\n";
    exit 1;
  }
  if ( !$rcExclude ) {
    $rcExclude = $args;
  } else {
    $rcExclude .= "," . $args;
  }
}

sub ignoreSubs {
  my ($args) = @_;
  if ( !defined($args) ) {
    print "missing IGNORESUBS arguments in .krazy...exiting\n";
    exit 1;
  }
  push( @rcIgSubsList, split( ",", $args ) );
}

sub ignoreMods {
  my ($args) = @_;
  if ( !defined($args) ) {
    print "missing IGNOREMODS arguments in .krazy...exiting\n";
    exit 1;
  }
  push( @rcIgModsList, split( ",", $args ) );
}

sub skips {
  my ($args) = @_;
  if ( !defined($args) ) {
    print "missing SKIP arguments in .krazy...exiting\n";
    exit 1;
  }
  $args =~ s+\\\|+|+g;
  if ( !$rcSkipRegex ) {
    $rcSkipRegex = $args;
  } else {
    if ($args) {
      $rcSkipRegex .= "|" . $args;
    }
  }
}

sub priority {
  my ($args) = @_;
  if ( !defined($args) ) {
    print "missing PRIORITY argument in .krazy...exiting\n";
    exit 1;
  }
  $args=lc($args);
  if ( !&validatePriorityType($args) ) {
    print "invalid PRIORITY argument \"$args\" in .krazy... exiting\n";
    exit 1;
  }
  $rcPriority = $args;
}

sub strict {
  my ($args) = @_;
  if ( !defined($args) ) {
    print "missing STRICT argument in .krazy...exiting\n";
    exit 1;
  }
  $args=lc($args);
  if ( !&validateStrictType($args) ) {
    print "invalid STRICT argument \"$args\" in .krazy... exiting\n";
    exit 1;
  }
  $rcStrict = $args;
}

sub output {
  my ($args) = @_;
  if ( !defined($args) ) {
    print "missing OUTPUT argument in .krazy...exiting\n";
    exit 1;
  }
  $args=lc($args);
  if ( !&validateOutputType($args) ) {
    print "invalid OUTPUT argument \"$args\" in .krazy... exiting\n";
    exit 1;
  }
  $rcOutput = $args;
}

sub export {
  my ($args) = @_;
  if ( !defined($args) ) {
    print "missing EXPORT argument in .krazy...exiting\n";
    exit 1;
  }
  $args=lc($args);
  if ( !&validateExportType($args) ) {
    print "invalid EXPORT argument \"$args\" in .krazy... exiting\n";
    exit 1;
  }
  $rcExport = $args;
}

1;
