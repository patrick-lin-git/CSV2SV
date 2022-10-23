#!/bin/perl

use strict;
use warnings;
use Text::CSV;

my $csv = Text::CSV->new({ sep_char => ',' });



my $user_name = $ENV{'USER'};
my $date_str  = "+\"%b%d %Y  %T\"";
my $run_time  = `date $date_str`;
chomp ($run_time);


if(@ARGV < 1) {
 #print_help();
 #print "Usage:\n\tppp src_file \"\/\/\"\n";
 #print "\tppp -h for help\n";
 die "Please specify input file name or use \'-h\' for help\n";
} else {
 if( $ARGV[0] eq "-h" ) {
  print_help();
 } else {
  print "input  file:  $ARGV[0]\n";
  print "output file   $ARGV[1]\n";
 }
}

my $csv_f = $ARGV[0];
my $rdf_f = $ARGV[1];

my $out_str ="";
my $cmt     = "\/\/";

$out_str .= $cmt." ---------------------------------------------------\n";
$out_str .= $cmt." This is a csv2rdf auto-generated file. DO NOT EDIT!\n";
$out_str .= $cmt." Source File: $csv_f\n";
$out_str .= $cmt." By user: $user_name, $run_time\n";  
$out_str .= $cmt." ---------------------------------------------------\n";


#-------------------------------------------------------------
open (FH, '<', $csv_f) or die $!;

my @lp_ary = ();

my $f1st_lp = 1;

my $lp_cont = 0; 
my $lp_base = 0; 
my $lp_incr = 0; 
my $lp_varb = "iii"; 

my $cur_ofs = 0;

my $cur_fbs = 0;     # field base

my $data_bus_width = 0;

my $loop_en;

while (<FH>) {
 my $line = $_;
 my @fld_ary;

 if ($csv->parse($line)) {
  @fld_ary = $csv->fields();
 } else {
  warn "Line could not be parsed by CSV module: $line\n";
 }

 if( $line =~ /^WR_DATA,/ ) {
  my @data_bus = split(',', $line);
   $data_bus_width = $data_bus[2];
 }
 
 if( $line =~ /^LOOP/ ) {
  $lp_cont = $fld_ary[1]; 
  $lp_base = $fld_ary[2]; 
  $lp_incr = $fld_ary[3]; 
  $lp_varb = $fld_ary[4]; 
  chomp($lp_varb);

# print "LOOP Options: $lp_cont, $lp_base, $lp_incr, $lp_varb\n";

  $lp_cont-- ;
  if( $f1st_lp == 1 ) {
   $out_str .= ":: my \@lp_range = (0..$lp_cont);\n";
  } else {
   $out_str .= "::    \@lp_range = (0..$lp_cont);\n";
  }

  $out_str .= ":: my \$"."$lp_varb = $lp_base;\n";
  $out_str .= ":: for my \$idx (\@lp_range) {\n";

  $f1st_lp = 0;
  $loop_en = 1;
  next;
 }

 if( $line =~ /^ENDLOOP/ ) {
  $out_str .= "::  \$"."$lp_varb += $lp_incr;\n";
  $out_str .= ":: }\n";
  $loop_en = 0;
  next;
 }

 if( $line =~ /^X\+/ ) {
 #$line =~ s/^\"X\+//;
  $cur_ofs++;
  my $hex_ofs = sprintf ("%X", $cur_ofs);
  shift(@fld_ary);
  my $str = ary2str(@fld_ary);
  $line = "X$hex_ofs,$str";
  $cur_fbs = 0;
  $out_str .= $line."\n";
  next;
 }

 if( $line =~ /^X([\d|\w]+),/ ) {
# print "\n== $cur_ofs ==\n";
  $cur_ofs = hex($1);
  $cur_fbs = 0;
  my $str = ary2str(@fld_ary);
  $line = "$str\n";
  $out_str .= $line;
  next;
 }

 if( $line =~ /^X.+/ ) {
  $cur_fbs = 0;
  my $str = ary2str(@fld_ary);
# $line = "$str\n";
  $out_str .= "$str\n";
  next;
 }

 # adjust bit range
#if( $line =~ /^,\"(\d+)\",/ ) {
 if( $line =~ /^,(\d+),/ ) {
  my $wid = $1;

# $line =~ s/^,\"\d+\",//;
  shift(@fld_ary);
  shift(@fld_ary);

  my $msb = $cur_fbs + $wid - 1;
  my $rag_str = "$msb:$cur_fbs";

  my $str = ary2str(@fld_ary);

  $line = ",$rag_str,". $str."\n";
  $cur_fbs += $wid;

  if( $cur_fbs >= $data_bus_width ) {
   die "Bit offset $cur_fbs within the register is out of range: $data_bus_width\n";
  }
 }

 if( $line =~ /^\"\/\// ) {
  $line =~ s/^\"//;
  $line =~ s/\",*$//;
 }

 $line =~ s/^,+$//;

 if( ($line =~ /^\"CHIPSEL/) or ($line =~ /^\"ADR_BUS/) or ($line =~ /^\"RD_DATA/) ) {
  $line =~ s/\"//g;
 }

 if( ($line =~ /^\"WR_DATA/) or ($line =~ /^\"WR_CTRL/) or ($line =~ /^\"RD_CTRL/) ) {
  $line =~ s/\"//g;
 }

 if( ($line =~ /^\"CLK_SIG/) or ($line =~ /^\"RST_SIG/) or ($line =~ /^\"RDD_DLY/) ) {
  $line =~ s/\"//g;
 }

 $out_str .= $line;

}
close(FH);


open (FH, '>', $rdf_f) or die $!;

print FH $out_str;




#-------------------------------------------------------------
sub print_help {
 print "Usage:\n";
 print "\tcsv2rdf src_file \n\n";
 print "Example:\n";
 print "\tcsv2rdf src.xxx.csv \"\/\/\"\n";
 print "\tcsv2rdf src.xxx.csv \"#\"\n\n";
 print "Source file in-line command:\n";
 print "Bug Report:\n";
 print "\tpatrickxlin\@gmail.com\n";
}

sub ary2str {
 my @ary = @_;
 my $str = "";
 foreach my $cel (@ary) {

  if( $cel =~ /[,|\s]/ ) {
   $cel = "\"".$cel."\"";
  }

  if( $cel =~ /<\S+>/ ) {
   $cel =~ s/</'\$/g;
   $cel =~ s/>/'/g;
  }

  $str .= "$cel,";
 }
 $str =~ s/,$//;
 return $str;
}
