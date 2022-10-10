#!/usr/bin/perl

# 32b data bus write-byte-enable control (strobe) is TBD

use strict;
use warnings;

if($#ARGV < 0) {
 print "Usage:\n";
 print "  doc2sv.pl rdf_file [out_file]\n\n";
 print "              rdf_file:      register definition file, an text file that parsed by this utility\n";
 print "              out_file:      optional output file name, default file ext name is the .rtl\n\n";
 print "Example\n";
 print " ./doc2sv.pl src.rdf out.rtl\n\n";
 print "Note:\n";
 print " 1.Please flow RDF file format\n";
 print " 2.This program also generate the C Header (*.h) file for firmware programming\n";
 print " 3.Some register attribute are still under developement\n\n";
 print "Author: Patrick LIN, patrickxlin\@gmail.com\n";
 die   "\n";
}

open(IN_RDF, "$ARGV[0]") || die "Can't open $ARGV[0]\n";

my $rdf_file = $ARGV[0];

# prefix name is fixed as "R_"
# my $rg_prefix;
# check optional 3'rd argument
# if( !$ARGV[2] ) {
#  $rg_prefix = ""; 
# } else {
#  $rg_prefix = $ARGV[2]; 
# }




my $cs_sig_name;
my $cs_sig_polr;
my $cs__is_def = 0;

my $addr_bus_name;
my $addr_bus_widt;
my $adr_is_def = 0;

my $rddt_bus_name;
my $rddt_bus_widt;
my $rdd_is_def = 0;

my $wrdt_bus_name;
my $wrdt_bus_widt;
my $wrd_is_def = 0;

my $rd_ctrl_name;
my $rd_ctrl_polr;
my $rdc_is_def = 0;

my $wr_ctrl_name;
my $wr_ctrl_polr;
my $wdc_is_def = 0;

my $clk_name;
my $clk_polr;
my $clk_is_def = 0;

my $rst_name;
my $rst_polr;
my $rst_is_def = 0;

my $rd_delay;
my $rdx_is_def = 0;

my $all_define = 0;

my $line;

while ($line = <IN_RDF>) {
 chomp ($line);

 if($line =~ /^CHIPSEL\s*,([\w|\d]+)\s*,([\w]+)/ ) {
   $cs_sig_name = $1;
   $cs_sig_polr = uc($2);
   $cs__is_def = 1;
 } 

 if($line =~ /^ADR_BUS\s*,([\w|\d]+)\s*,([\d]+)/ ) {
   $addr_bus_name = $1;
   $addr_bus_widt = $2;
   $adr_is_def = 1;
 } 

 if($line =~ /^RD_DATA\s*,([\w|\d]+)\s*,([\d]+)/ ) {
   $rddt_bus_name = $1;
   $rddt_bus_widt = $2;
   $rdd_is_def = 1;
 } 

 if($line =~ /^WR_DATA\s*,([\w|\d]+)\s*,([\d]+)/ ) {
   $wrdt_bus_name = $1;
   $wrdt_bus_widt = $2;
   $wrd_is_def = 1;
 } 

 if($line =~ /^RD_CTRL\s*,([\w|\d]+)\s*,([\w]+)/ ) {
   $rd_ctrl_name = $1;
   $rd_ctrl_polr = uc($2);
   $rdc_is_def = 1;
 }

 if($line =~ /^WR_CTRL\s*,([\w|\d]+)\s*,([\w]+)/ ) {
   $wr_ctrl_name = $1;
   $wr_ctrl_polr = uc($2);
   $wdc_is_def = 1;
 }

 if($line =~ /^CLK_SIG\s*,([\w|\d]+)\s*,([\w]+)/ ) {
   $clk_name   = $1;
   $clk_polr   = uc($2);
   $clk_is_def = 1;
 }

 if($line =~ /^RST_SIG\s*,([\w|\d]+)\s*,([\w]+)/ ) {
   $rst_name   = $1;
   $rst_polr   = uc($2);
   $rst_is_def = 1;
 }

 if($line =~ /^RDD_DLY\s*,(\d)/ ) {
   $rd_delay = $1;
   $rdx_is_def = 1;
 }

 if( $cs__is_def == 1 &&
     $adr_is_def == 1 &&
     $rdd_is_def == 1 &&
     $wrd_is_def == 1 &&
     $rdc_is_def == 1 &&
     $wdc_is_def == 1 &&
     $clk_is_def == 1 &&
     $rst_is_def == 1 &&
     $rdx_is_def == 1 ) {
  $all_define = 1;
  print "RDF File: $ARGV[0] Pre-Integrity Check Pass!!\n";
  last;
 }
}   # while


if( !$all_define ) {
  print "Not all I/O interface was defined\n";
  print "CHIPSEL ";
  print $cs__is_def;
  print "\nADR_BUS ";
  print $adr_is_def;
  print "\nRD_DATA ";
  print $rdd_is_def;
  print "\nWR_DATA ";
  print $wrd_is_def;
  print "\nRD_CTRL ";
  print $rdc_is_def;
  print "\nWR_CTRL ";
  print $wdc_is_def;
  print "\nCLK_SIG ";
  print $clk_is_def;
  print "\nRST_SIG ";
  print $rst_is_def;
  print "\nRDD_DLY ";
  print $rdx_is_def;
  print "\n";
  die;
}

my %regn_hsh = ();    # reg name to offset
my %rego_hsh = ();    # offset to reg name

while ($line = <IN_RDF>) {
 chomp ($line);

 $line = rm_dq($line);

#print "-- $line --\n";

 if( $line =~ /^[x|X]([\d|\w]+)\s*,([\w|\d]+)/ ) {
  my $reg_ofst = uc($1);
  my $ofs_len = length($reg_ofst);

  if( $addr_bus_widt > 12 ) {
   if( $ofs_len > 4 ) {
    die "Register Offset Address Range $reg_ofst over address bus width range: $addr_bus_widt";
   } 
  } else {
   if( $addr_bus_widt > 8 ) {
    if( $ofs_len > 3 ) {
     die "Register Offset Address Range $reg_ofst over address bus width range: $addr_bus_widt";
    } 
   } else {
    if( $addr_bus_widt > 4 ) {
     if( $ofs_len > 2 ) {
      die "Register Offset Address Range $reg_ofst over address bus width range: $addr_bus_widt";
     } 
    } else {                     # <= 4
     if( $ofs_len > 1 ) {
      die "Register Offset Address Range $reg_ofst over address bus width range: $addr_bus_widt";
     } 
    }
   }
  }

  my $reg_name = lc($2);

# print "-- $line --\n";
# print "-- $reg_ofst $reg_name --\n";

  if( not_hex_str($reg_ofst) ) {
   die "Register Offset Address format should be in hex: $reg_ofst";
  }

  if( exists $rego_hsh{$reg_ofst} ) {
   die "This register address $reg_ofst is redefined\n";
  } else {
   $rego_hsh{$reg_ofst} = $reg_name;
   #print "$reg_name\n";
  }

  if( exists $regn_hsh{$reg_name} ) {
   die "This register name $2 is redefined\n";
  } else {
   $regn_hsh{$reg_name} = $reg_ofst;
   #print "$2\n";
  }
 }
}


# get longest reg name string
my $reg_n_len=0;
foreach ( keys %rego_hsh ) {
 my $str = $rego_hsh{$_};
 my $len = length($str);
 if( $len > $reg_n_len ) {
  $reg_n_len = $len;
 }
}

my $adr_par_str = "localparam ";

foreach ( keys %rego_hsh ) {
 my $ofs = $_;
 my $str = $rego_hsh{$_};
 my $len = length($str);
 my $spc = blank_spc($reg_n_len - $len);

 $ofs = get_ofst ($ofs);
 
 $adr_par_str .= "p".uc($rego_hsh{$_}).$spc." = ".$addr_bus_widt."'h".$ofs.",\n";
}

$adr_par_str =~ s/\np/\n           p/g;
$adr_par_str =~ s/,\n$/;\n/g;

# print "$adr_par_str\n";

my $adr_dec_str = "";

my $cs_wire;
if( $cs_sig_polr eq "LOW") {
 $cs_wire = "~".$cs_sig_name;
} else {
 $cs_wire = $cs_sig_name;
}

foreach ( keys %rego_hsh ) {
 # print $_." ".$rego_hsh{$_}."\n";
 my $str = $rego_hsh{$_};
 my $len = length($str);
 my $spc = blank_spc($reg_n_len - $len);
 $adr_dec_str .= "wire ".$rego_hsh{$_}."_hit $spc = (".$cs_wire." & (".$addr_bus_name." == p".uc($rego_hsh{$_}).")$spc)? 1'b1 : 1'b0;\n";
}


# ------------------------------------------------------- 
# read from begining
seek(IN_RDF, 0,0);
# parsing each sub_field

my %reg_sub_f = ();    # hash of all registrs, key is register name, each hash value is an array
my %field_nam = ();    # global field name
my @all_sub_f = ();    # array of all register field to one specific register, array of array (2D)

my $f1st_scn  = 1;

my $offs;
my $regn;

# ------------------------------------------------------- 
while ( $line = <IN_RDF> ) {
 chomp ( $line );
 $line = rm_dq($line);

 if( $line =~ /^[X|x]([\d|\w]+)\s*,([\w|\d]+),/ ) {

  if( $f1st_scn == 1) {
   $offs = uc($1);
   $regn = lc($2);
  } else {

#  print "  \n";
#  foreach (@all_sub_f) {
#   print "== $_ ==\n";
#   my @ary_x = @{$_};
#   print "== @ary_x ==\n";
#  }

#  $reg_sub_f{uc($regn)} = \@all_sub_f;
   $reg_sub_f{$regn} = [@all_sub_f];
   $offs = uc($1);
   $regn = lc($2);
  }

  if( exists $rego_hsh{$offs} ) {
   @all_sub_f = ();
  } else {
   print "Internal Error, unknown register offset $offs";
  }
  $f1st_scn = 0;
 }

 if( $line =~ /^[\s|\t]*,([\d|\:]+)\s*,([\w|\d]+)\s*,([\w|\d]+)\s*,([\w|\d]+)\s*/ ) {
  # print "offs => ".$offs." regn => ".$regn."\n";
  # print "bit_size  => ".$1."\n";
  # print "default   => ".$2."\n";            # hex or decimal, reset default
  # print "attribute => ".$3."\n";            # access attribute
  # print "sub_field => ".$4."\n";            # sub_field name
  my $rang = $1;                              # bit range
  my $dflt = uc($2);                          # default value
  my $atrb = uc($3);                          # attrib
  my $fldn = lc($4);                          # field name
  if( not_hex_str(uc($dflt)) ) {
   die "Reset Default $dflt is not in valid format, should be in hex";
  }

  my $opt1="";
  my $opt2="";
  # check extra options
  if( $line =~ /^,.+?,.+?,.+?,.+?,.*?,([\w|\d]+),/ ) {
   $opt1 = $1;
  }
  if( $line =~ /^,.+?,.+?,.+?,.+?,.*?,.*?,([\w|\d]+)/ ) {
   $opt2 = $1;
  }

# print "= $opt1 = $opt2 =\n";
  
  my @sub_field = ($rang, $dflt, $atrb, $fldn, $opt1, $opt2);

  if( exists $field_nam{$fldn} ) {
   die "ERROR!! filed name $fldn has been defined before\n";
  } else {
   $field_nam{$fldn}  = $rang;
  }

  push @all_sub_f, [ @sub_field ] ;
# push(@all_sub_f,  \@sub_field ) ;
# push(@all_sub_f,   @sub_field ) ;
 }

 if( $line =~ /^,,,,,/ ) {
  next;
 }

}  # while

# last one
$reg_sub_f{$regn} = [@all_sub_f];






# --------------------------------
# dump all register
# --------------------------------
# dump_rdf();

my $out_port_lst ="";
my $out_port_dir ="";
foreach ( keys %reg_sub_f ) {
 my $all_sub_fld = $reg_sub_f{$_};

 # print "$all_sub_fld\n";
 # print "$_\n";

 my @all_sub_fry = @{$all_sub_fld};

 # print "@all_sub_fry\n";

 foreach my $xx (@all_sub_fry) {

  my @x_ary =  @{$xx};

# print "== $x_ary[3] ==\n";
# print "== @x_ary ==\n";
# print "== $x_ary[3] ==\n";

  my $range  = $x_ary[0];
  my $f_rdef = $x_ary[1];
  my $attrb =  $x_ary[2];
  my $f_name = $x_ary[3];

  my @ranga = split(':', $range);
  my $msb   = $ranga[0];
  my $lsb   = $ranga[1];
  my $width = $msb - $lsb + 1;;
  my $widt1 = $width - 1;;

# print "== $width  ==\n";
# print "== $f_rdef ==\n";
# print "== $attrb  ==\n";
# print "== $f_name ==\n";

  if( $attrb =~ /X/ ) {
   print "Found pure software scratch register, $f_name\n";
  } else {
   $out_port_lst .= " R_".uc($f_name).",\n";
   if( $width >  1 ) {
    if( $width >= 10 ) {
     $out_port_dir .= " output logic [$widt1:0] R_".uc($f_name).",\n";
    } else {
     $out_port_dir .= " output logic  [$widt1:0] R_".uc($f_name).",\n";
    }
   } else {
    $out_port_dir .= " output logic        R_".uc($f_name).",\n";
   }

   if( $attrb =~ /C/ ) {
    $out_port_lst .= " H_CLR_".uc($f_name).",\n";
    $out_port_dir .= " input  logic        H_CLR_".uc($f_name).",\n";
   }
   if( $attrb =~ /S/ ) {
    $out_port_lst .= " H_SET_".uc($f_name).",\n";
    $out_port_dir .= " input  logic        H_SET_".uc($f_name).",\n";
   }
   if( $attrb =~ /F/ ) {
    $out_port_lst .= " R_ACK_".uc($f_name).",\n";
    $out_port_dir .= " output  logic       R_ACK_".uc($f_name).",\n";
   }

  }

  if( ($attrb =~ /W/) && ($attrb =~ /1/)) {
   print "ERR!,".$f_name." Attribute: $attrb, Software Write and Write 1 Clear can not be defined at the same time\n";
   die;
  }

  if( ($attrb =~ /W/) && ($attrb =~ /S/)) {
   print "ERR!,".$f_name." Attribute: $attrb, Hard Set and Software Write can not be defined at the same time\n";
   die;
  }

 }
}

# $out_port_lst =~ s/\,$//;
$out_port_dir =~ s/\,$//;

# print $out_port_lst;

# print $out_port_dir;
my $rddt_wid = $rddt_bus_widt - 1;

# ------------------------------------------------------------
# read logic
my %rd_out   = ();
my %rd_out_w = ();
my %rd_out_l = ();
my $msb;
my $width;
foreach ( keys %reg_sub_f ) {
 my $reg_n = $_;
 my $all_sub_fld = $reg_sub_f{$_};
 my $comb = "";
 foreach my $xx (@$all_sub_fld) {
  my $attrb =  $xx->[2];
  my $range =  $xx->[0];
  my @ranga = split(':', $range);
     $msb   = $ranga[0];
  my $lsb   = $ranga[1];
     $width = $msb - $lsb + 1;;
  my $widt1 = $width - 1;;

  if( $lsb > ($msb + 1) ) {
   $width = $lsb - $msb - 1;
   if( $width > 1 ) {
    if( $width > 4 ) {
     $comb = $width."'h00"." ,".$comb;
    } else {
     $comb = $width."'h0"." ,".$comb;
    }
   } else {
    $comb = "1'b0"." ,".$comb;
   }
  }

  if( $attrb =~ /R/ ) {
   $comb = "R_".uc($xx->[3])." ,".$comb;
  } else {                                 # not readable
   if($width > 1) {
    if($width > 4) {
     $comb = "$width"."'h00"." ,".$comb;
    } else {
     $comb = "$width"."'h0"." ,".$comb;
    }
   } else {
    $comb = "$width"."'b0"." ,".$comb;
   }
  }
 }

 if( ($rddt_bus_widt-1) > $msb ) {
  $width = $rddt_bus_widt - $msb - 1;
  if( $width > 1 ) {
   if( $width > 4 ) {
    $comb = $width."'h00"." ,".$comb;
   } else {
    $comb = $width."'h0"." ,".$comb;
   }
  } else {
   $comb = "1'b0"." ,".$comb;
  }
 }
 $comb =~ s/,$//g;
 
#my $rd_out_name = lc($rego_hsh{$reg_n})."_rd"; 


 my $rd_out_name = $reg_n."_rd"; 
 $rd_out_w{$reg_n} = $rd_out_name;
 $rd_out_l{$reg_n} = "wire [$rddt_wid:0] $rd_out_name = { ".$comb." };\n";
}

# foreach ( keys %rego_hsh ) {
# print $rd_out{$reg_n};
# }

my $rd_out_mux;
$rd_out_mux  = "reg  [$rddt_wid:0] rd_out;\n";
$rd_out_mux .= "always_comb @(*)\n";
$rd_out_mux .= " case ($addr_bus_name)\n";


# foreach ( keys %rd_out_w ) {
#  print "=== $_ $rd_out_w{$_} ===\n"; 
# }


foreach ( keys %rego_hsh ) {
 my $n_reg = $rego_hsh{$_};
#print "=== $_ $n_reg ===\n"; 

 my $len = length($n_reg);
 my $spc = blank_spc($reg_n_len - $len);

 $rd_out_mux .= "  p".$n_reg."$spc: rd_out = ".$rd_out_w{$n_reg}.";\n";
#$rd_out_mux .= "  p".$n_reg;
}

 my $spc = blank_spc($reg_n_len - 6);

if( $rddt_bus_widt == 8 ) {
 $rd_out_mux .= "  default"."$spc: rd_out = $rddt_bus_widt"."'h00;\n";
} else {
 $rd_out_mux .= "  default"."$spc: rd_out = $rddt_bus_widt"."'h0000_0000;\n";
}
$rd_out_mux .= " endcase\n";



# ------------------------------------------------------------
# write logic

my $clk_rst;

if( uc($clk_polr) eq "NEG" ) {
 if( uc($rst_polr) eq "POS" ) {
  $clk_rst  = "always_ff @(negedge $clk_name or posedge $rst_name)\n";
 } else {
  $clk_rst  = "always_ff @(negedge $clk_name or negedge $rst_name)\n";
 }
} else {
 if( uc($rst_polr) eq "POS" ) {
  $clk_rst  = "always_ff @(posedge $clk_name or posedge $rst_name)\n";
 } else {
  $clk_rst  = "always_ff @(posedge $clk_name or negedge $rst_name)\n";
 }
}

my %wr_logic = ();
foreach ( keys %reg_sub_f ) {
 my $reg_n = $_;
 my $all_sub_fld = $reg_sub_f{$_};

 my $reg_hit =  $reg_n."_hit";
 my $comb = "";
 my $lsb;

 # register decalation
 foreach my $xx ( @$all_sub_fld ) {
  my $range = $xx->[0];

  my @ranga = split(':', $range);
  my $msb   = $ranga[0];
     $lsb   = $ranga[1];
  my $width = $msb - $lsb + 1;;
  my $widt1 = $width - 1;;


  if( $width > 1 ) {
   if( $width > 9 ) {
    $comb  .= "reg [".$widt1.":0] R_".uc($xx->[3]).";\n";
   } else {
    $comb  .= "reg  [".$widt1.":0] R_".uc($xx->[3]).";\n";
   }
  } else {
   $comb  .= "reg        R_".uc($xx->[3]).";\n";
  }
 }


 $comb .= $clk_rst;

 if( $rst_polr eq "POS" ) {
  $comb .= " if( $rst_name )";
 } else { 
  $comb .= " if( ~$rst_name )";
 }

 if( @$all_sub_fld > 1 ) {
  $comb .= " begin\n";
  foreach my $xx ( @$all_sub_fld ) {
   my $attrb = $xx->[2];

   my $range = $xx->[0];
   my @ranga = split(':', $range);
   my $msb   = $ranga[0];
   my $lsb   = $ranga[1];
   my $width = $msb - $lsb + 1;;


   # if( $attrb =~ /W/ ) {
   my $reg_name = uc($xx->[3]);
#  my $field_wd = $xx->[0] - $xx->[1] + 1;
   if( ($width < 5) && (length($xx->[1]) > 1) ) {
    print "ERR! Reg: ".$reg_name." Reset Default Out of Range:".$xx->[1]."\n";
    die;
   }
   if( ($width > 4) && (length($xx->[1]) < 2) ) {
    print "ERR! Reg: ".$reg_name." field width is $width but High bit of Reset Default not defined:".$xx->[1],"\n";
    die;
   }
   if( ($width > 8) && (length($xx->[1]) < 3) ) {
    print "ERR! Reg: ".$reg_name." field width is $width but High bit of Reset Default not defined:".$xx->[1],"\n";
    die;
   }
   if( ($width >12) && (length($xx->[1]) < 4) ) {
    print "ERR! Reg: ".$reg_name." field width is $width but High bit of Reset Default not defined:".$xx->[1],"\n";
    die;
   }
   if( ($width >16) && (length($xx->[1]) < 5) ) {
    print "ERR! Reg: ".$reg_name." field width is $width but High bit of Reset Default not defined:".$xx->[1],"\n";
    die;
   }
   $comb .= "  R_".$reg_name." <= ".$width."'h".$xx->[1].";\n";
   # }
  }

  $comb .= "  end\n else begin\n";

  if( $wr_ctrl_polr eq "HIGH" ) {
   $comb .= "  if ( $reg_hit & $wr_ctrl_name ) begin\n";
  } else {
   $comb .= "  if ( $reg_hit & ~".$wr_ctrl_name." ) begin\n";
  }

  foreach my $xx ( @$all_sub_fld ) {
   my $attrb = $xx->[2];
   my $reg_n = uc($xx->[3]);

   if( ($attrb =~ /T/) and ($attrb =~ /W/) ) {
    print "ERR! Reg: ".$reg_n." has field attribute: $attrb both W and T specified\n";
   }

   if( $attrb =~ /W/ ) {
    my $rang = $xx->[0];
  # print "= $rang =\n";
  # my $width = get_width($xx->[0]);
    my $width = get_width($rang);
    my $lsb   = get_lsb  ($rang);
    if( $width > 1 ) {
     $comb .= "   R_".$reg_n." <= ".$wrdt_bus_name."[".$xx->[0]."];\n";
    } else {
     $comb .= "   R_".$reg_n." <= ".$wrdt_bus_name."[  $lsb"."];\n";
    }
   }

   if( $attrb =~ /T/ ) {
    my $rang = $xx->[0];
  # print "= $rang =\n";
  # my $width = get_width($xx->[0]);
    my $width = get_width($rang);
    if( $width > 1 ) {
     print "ERR! Reg: ".$reg_n." field width $width is greater than 1 with T attribute specified:".$attrb,"\n";
    }
    my $lsb   = get_lsb($rang);

#   $comb .= "   if( R_".$reg_n." )\n";
#   $comb .= "    R_".$reg_n." <= 1'b0;\n";
#   $comb .= "   else\n";
    $comb .= "   R_".$reg_n." <= ~R_".$reg_n." & ".$wrdt_bus_name."[  $lsb"."];\n";
   }
  }

  $comb .= "  end\n";

  foreach my $xx ( @$all_sub_fld ) {
   my $attrb = $xx->[2];
   my $reg_n = uc($xx->[3]);
#  my $rang = $xx->[0];
#  my $lsb  = get_lsb  ($rang);
   if( $attrb =~ /T/ ) {

    $comb .= "\n";
    $comb .= "  if( R_".$reg_n." )\n";
    $comb .= "   R_".$reg_n." <= 1'b0;\n\n";
#   $comb .= "  else\n";
#   $comb .= "   R_".$reg_n." <= ".$wrdt_bus_name."[  $lsb"."];\n";
   }
  }


  foreach my $xx ( @$all_sub_fld ) {
   my $attrb =  $xx->[2];
   my $reg_n = uc($xx->[3]);
   if( $attrb =~ /C/ ) {              # hardware clear
    $comb .= "  if ( H_CLR_".$reg_n." )\n";

    my $field_wd = get_width($xx->[0]);

    if( $field_wd > 1 ) {
     print "ERR! $reg_n Field width > 1, Hardware Clr is not allowed\n";
     die;
    } else {
     $comb .= "   R_".$reg_n." <= 1"."'b0;\n";
    }
   }
  }

  foreach my $xx ( @$all_sub_fld ) {
   my $attrb = $xx->[2];
   my $reg_n = uc($xx->[3]);
   if( $attrb =~ /S/ ) {              # hardware clear
    $comb .= "  if ( H_SET_".$reg_n." )\n";
    my $field_wd = get_width($xx->[0]);
    if( $field_wd > 1 ) {
     print "ERR! $reg_n Field width > 1, Hardware Set is not allowed\n";
     die;
    } else {
     $comb .= "   R_".$reg_n." <= 1"."'b1;\n";
    }
   }
  }

  foreach my $xx ( @$all_sub_fld ) {
   my $range = $xx->[0];
   my @ranga = split(':', $range);
   my $msb   = $ranga[0];
   my $lsb   = $ranga[1];
   my $width = $msb - $lsb + 1;
   my $widt1 = $width - 1;;

   my $attrb = $xx->[2];
   my $reg_n = uc($xx->[3]);

   if( $attrb =~ /1/ ) {              # write 1 clear

    if( $wr_ctrl_polr eq "HIGH" ) {
     $comb .= "  if ( $reg_hit & $wr_ctrl_name & $wrdt_bus_name"."[  $lsb]"."])\n";
    } else {
     $comb .= "  if ( $reg_hit & ~"."$wr_ctrl_name & $wrdt_bus_name"."[  $lsb]"."])\n";
    }

    if( $width > 1 ) {
     print "ERR! Field width > 1, Write 1 clear is not allowed\n";
     die;
    } else {
     $comb .= "   R_".$reg_n." <= ".$width."'b0;\n";
    }
   }
  }

  $comb .= " end\n\n";
 } else { # only one register
  my $attrb;
  my $reg_n;
  my $f_wid;
# print "== $attrb $reg_n $f_wid == \n";
  foreach my $xx ( @$all_sub_fld ) {
   $attrb = $xx->[2];
   $reg_n = uc($xx->[3]);
   $f_wid = get_width($xx->[0]);
   if( $attrb =~ /W/ ) {
    if( ($f_wid < 5) && (length($xx->[1]) > 1) ) {
     print "ERR! Reg: ".$reg_n." Reset Default Out of Range:".$xx->[1]."\n";
     die;
    }
    if( ($f_wid > 4) && (length($xx->[1]) < 2) ) {
     print "ERR! Reg: ".$reg_n." High bit of Reset Default not defined: ".$xx->[1]."\n";
     die;
    }
    $comb .= "\n  R_".$reg_n." <= ".$f_wid."'h".$xx->[1].";\n";
   }
  }

  
  if( ($attrb =~ /C/) || ($attrb =~ /S/) ) {
   $comb .= " else begin\n";
  } else {
   $comb .= " else\n";
  }

  if( $wr_ctrl_polr eq "HIGH" ) {
   $comb .= "  if ( $reg_hit & $wr_ctrl_name )\n";
  } else {
   $comb .= "  if ( $reg_hit & ~".$wr_ctrl_name." )\n";
  }

  foreach my $xx ( @$all_sub_fld ) {
   $attrb = $xx->[2];
   $reg_n = uc($xx->[3]);
   $f_wid = get_width($xx->[0]);
   my $lsb = get_lsb($xx->[0]);
   if( $attrb =~ /W/ ) {
    if( $f_wid > 1 ) {
     $comb .= "   R_".$reg_n." <= ".$wrdt_bus_name."[".$xx->[0]."];\n";
    } else {
     $comb .= "   R_".$reg_n." <= ".$wrdt_bus_name."[".$lsb."];\n";
    }
   }
  }
  $comb .= "\n";

  foreach my $xx ( @$all_sub_fld ) {
   $attrb = $xx->[2];
   $f_wid = get_width($xx->[0]);
   $reg_n = uc($xx->[3]);
   if( $attrb =~ /C/ ) {
    $comb .= "  if ( H_CLR_".$reg_n." )\n";
    if( $f_wid > 1 ) {
     print "ERR! $reg_n Field width > 1, Hardware Clr is not allowed\n";
     die;
    } else {
     $comb .= "   R_".$reg_n." <= ".$f_wid."'b0;\n";
    }
   }
  }

  foreach my $xx ( @$all_sub_fld ) {
   $attrb = $xx->[2];
   $reg_n = uc($xx->[3]);
   $f_wid = get_width($xx->[0]);
   if( $attrb =~ /S/ ) {
    $comb .= "  if ( H_SET_".$reg_n." )\n";
    if( $f_wid > 1 ) {
     print "ERR! $reg_n Field width > 1, Hardware Set is not allowed\n";
     die;
    } else {
     $comb .= "   ".$reg_n." <= ".$f_wid."'b0;\n";
    }
   }
  }


  if( ($attrb =~ /C/) || ($attrb =~ /S/) ) {
   $comb .= " end\n\n";
  }
 }
 # print $comb;
 $wr_logic{$_} = $comb;
}

# foreach ( keys %reg_sub_f ) {
#  print $wr_logic{$_};
# }




# --------------------------------------------------------
# prepare to output
my $rtl_file = `basename  $rdf_file`;
chomp($rtl_file);
$rtl_file =~ s/\..*$//g;

my $out_file;
if( $#ARGV < 1 ) {
 $out_file = $rtl_file.".rtl";
} else {
 $out_file = $ARGV[1];
}





my $mod_name = `basename  $out_file`;
chomp($mod_name);
$mod_name =~ s/\..*$//g;


my $tmp = uc($mod_name);
my $module_dec;
$module_dec  = "module $tmp (\n";

# $module_dec .= " $cs_sig_name,\n";
# $module_dec .= " $addr_bus_name,\n";
# $module_dec .= " $rddt_bus_name,\n";
# $module_dec .= " $wrdt_bus_name,\n";
# $module_dec .= " $wr_ctrl_name,\n";
# $module_dec .= " $rd_ctrl_name,\n";
# $module_dec .= " $clk_name,\n";
# $module_dec .= " $rst_name,\n";
# $module_dec .= " \n";
# $module_dec .= $out_port_lst.");\n";




my $port_dir_dec   = " input  logic        $cs_sig_name,\n";

$tmp = $addr_bus_widt-1;

if( $tmp >= 10 ) {
 $port_dir_dec .= " input  logic [$tmp:0] $addr_bus_name,\n";
} else {
 $port_dir_dec .= " input  logic  [$tmp:0] $addr_bus_name,\n";
}

$tmp = $rddt_bus_widt-1;
if( $tmp >= 10 ) {
 $port_dir_dec .= " output logic [$tmp:0] $rddt_bus_name,\n";
} else {  
 $port_dir_dec .= " output logic  [$tmp:0] $rddt_bus_name,\n";
}

$tmp = $wrdt_bus_widt-1;
if( $tmp >= 10 ) {
 $port_dir_dec .= " input  logic [$tmp:0] $wrdt_bus_name,\n";
} else {
 $port_dir_dec .= " input  logic  [$tmp:0] $wrdt_bus_name,\n";
}

$port_dir_dec .= " input  logic        $wr_ctrl_name,\n";
$port_dir_dec .= " input  logic        $rd_ctrl_name,\n";
$port_dir_dec .= " input  logic        $clk_name,\n";
$port_dir_dec .= " input  logic        $rst_name,\n\n";



# print $module_dec;
# print $port_dir_dec;
# print $out_port_dir;
# print "\n".$adr_par_str;
# print "endmodule\n";





print "RTL File: $out_file is generatd\n";


my $date = `date '+%m/%d/%y'`;
chomp($date);

my $veri_out_str;
$veri_out_str  = "// This Verilog file was auto-generated by \"doc2sv.pl\"\n";
$veri_out_str .= "// The source file was from \"$ARGV[0]\"\n";
$veri_out_str .= "// Date:  $date\n\n";

$veri_out_str .= "// ---------------------------------------------------\n";
$veri_out_str .= "// NOTE\:\n";
$veri_out_str .= "//      Please DO NOT edit this file !!\n";
$veri_out_str .= "//      *** Update Source Doc First ***\n";
$veri_out_str .= "// ---------------------------------------------------\n\n";


open(OUT_V, ">$out_file") || die "Can't Open $out_file\n";
print OUT_V $veri_out_str;
print OUT_V $module_dec;
print OUT_V $port_dir_dec;
print OUT_V $out_port_dir;
print OUT_V ");\n\n".$adr_par_str;
print OUT_V "\n$adr_dec_str\n";

foreach ( keys %reg_sub_f ) {
 print OUT_V "\/\/ -----------------------------------------------\n";
 print OUT_V $wr_logic{$_};
 print OUT_V $rd_out_l{$_};
 print OUT_V "\n\n\n";
}

print OUT_V "\n".$rd_out_mux."\n";

$tmp = $rddt_bus_widt - 1;

my $rdc_wire;
if( $rd_ctrl_polr eq "HIGH" ) {
 $rdc_wire = " ".$rd_ctrl_name;
} else {
 $rdc_wire = "~".$rd_ctrl_name;
}

if( $rd_delay == 1 ) {
 my $comb;
 print OUT_V "\nreg [$tmp:0] $rddt_bus_name;\n";
 print OUT_V $clk_rst;
 if( $rst_polr eq "POS" ) {
  $comb = " if(  $rst_name )\n";
 } else { 
  $comb = " if( !$rst_name )\n";
 }
 $comb .= "  $rddt_bus_name <= ".$rddt_bus_widt."'h00;\n";
 $comb .= " else\n";
 $comb .= "  if( ".$cs_wire." & ".$rdc_wire." )\n";
 $comb .= "   $rddt_bus_name <= rd_out;\n";

 print OUT_V $comb;
 
} else {
 print OUT_V "\nwire [$tmp:0] $rddt_bus_name;\n";
 print OUT_V "\nassign $rddt_bus_name = (".$cs_wire." & ".$rdc_wire.") ? rd_out : ".$rddt_bus_widt."'h00".";\n";
}
print OUT_V "\n\nendmodule\n";
close(OUT_V);

# ------------------------------------------------------
# generate C header file

my $hdr_file = lc($mod_name).".h";

open(OUT_C, ">$hdr_file") || die "Can't Open $hdr_file\n";

$veri_out_str =~ s/Verilog/C header/g;

print OUT_C $veri_out_str;
print OUT_C "#define SET_BIT0        0x01\n";
print OUT_C "#define SET_BIT1        0x02\n";
print OUT_C "#define SET_BIT2        0x04\n";
print OUT_C "#define SET_BIT3        0x08\n";
print OUT_C "#define SET_BIT4        0x10\n";
print OUT_C "#define SET_BIT5        0x20\n";
print OUT_C "#define SET_BIT6        0x40\n";
print OUT_C "#define SET_BIT7        0x80\n";
print OUT_C "#define SET_BIT8        0x0100\n";
print OUT_C "#define SET_BIT9        0x0200\n";
print OUT_C "#define SET_BIT10       0x0400\n";
print OUT_C "#define SET_BIT11       0x0800\n";
print OUT_C "#define SET_BIT12       0x1000\n";
print OUT_C "#define SET_BIT13       0x2000\n";
print OUT_C "#define SET_BIT14       0x4000\n";
print OUT_C "#define SET_BIT15       0x8000\n";

print OUT_C "\n";
print OUT_C "#define CHK_BIT0        0x01\n";
print OUT_C "#define CHK_BIT1        0x02\n";
print OUT_C "#define CHK_BIT2        0x04\n";
print OUT_C "#define CHK_BIT3        0x08\n";
print OUT_C "#define CHK_BIT4        0x10\n";
print OUT_C "#define CHK_BIT5        0x20\n";
print OUT_C "#define CHK_BIT6        0x40\n";
print OUT_C "#define CHK_BIT7        0x80\n";
print OUT_C "\n";

print OUT_C "#define CLR_BIT0        0xFE\n";
print OUT_C "#define CLR_BIT1        0xFD\n";
print OUT_C "#define CLR_BIT2        0xFB\n";
print OUT_C "#define CLR_BIT3        0xF7\n";
print OUT_C "#define CLR_BIT4        0xEF\n";
print OUT_C "#define CLR_BIT5        0xDF\n";
print OUT_C "#define CLR_BIT6        0xBF\n";
print OUT_C "#define CLR_BIT7        0x7F\n";
print OUT_C "#define CLR_BIT8        0xFEFF\n";
print OUT_C "#define CLR_BIT9        0xFDFF\n";
print OUT_C "#define CLR_BIT10       0xFBFF\n";
print OUT_C "#define CLR_BIT11       0xF7FF\n";
print OUT_C "#define CLR_BIT12       0xEFFF\n";
print OUT_C "#define CLR_BIT13       0xDFFF\n";
print OUT_C "#define CLR_BIT14       0xBFFF\n";
print OUT_C "#define CLR_BIT15       0x7FFF\n\n";



foreach ( keys %rego_hsh ) {
 my $ofs = $_;
 my $reg_n = $rego_hsh{$_};
 my $str_len = length($reg_n);

 my $ofss = get_ofst ($ofs);

 print OUT_C "#define ".$reg_n.blank_spc(14 - $str_len)." 0x".$ofss."\n";

 my $all_sub_fld = $reg_sub_f{$reg_n};
 foreach my $xx (@$all_sub_fld) {
  #print "==> $xx->[0] $xx->[1] $xx->[2] $xx->[3] $xx->[4] <==\n";

  my $rangs = $xx->[0];
  my @ranga = split(':', $rangs);
  my $msb   = $ranga[0];
  my $lsb   = $ranga[1];
  my $width = $msb - $lsb + 1;

  my $reg_n = uc($xx->[3]);            # register name
  if( $width > 1 ) {
   do {
    $width -= 1;
    my $str_len = length($reg_n."$width");
    if( $lsb + $width >= 10 ) {
     print OUT_C " #define _".$reg_n.$width.blank_spc(11 - $str_len)."SET_BIT".($lsb + $width)."   \/\/ ".$xx->[3]."\n";
    } else {
     print OUT_C " #define _".$reg_n.$width.blank_spc(11 - $str_len)."SET_BIT".($lsb + $width)."    \/\/ ".$xx->[3]."\n";
    }
   } while ( $width > 0 ) ;
  } else {
   my $str_len = length($reg_n." ");
   print OUT_C " #define _".$reg_n.blank_spc(12 - $str_len)."SET_BIT".$lsb."    \/\/ ".$xx->[3]."\n";
  }
 }
 print OUT_C "\n";
}

# foreach ( keys %reg_sub_f ) {
# $all_sub_fld = $reg_sub_f{$_};
# foreach $xx (@$all_sub_fld) {
#   print "==> $xx->[0] $xx->[1] $xx->[2] $xx->[3] $xx->[4] <==\n";
# }
#}

print "HDR File: $hdr_file is generatd\n";

close(OUT_C);

# ------------------------------------
# ------------------------------------
sub blank_spc {
 my $len_req = $_[0];
 my $spc_str = "";
 for (my $k = 0 ; $k <= $len_req ; $k++) {
  $spc_str .= " ";
 }
 return $spc_str;
}


sub not_hex_str {
 my( $str ) = @_;
 $str = uc($str);
 $str =~ s/\d//g;
 $str =~ s/[A|B|C|D|E|F]//g;
 if( length($str) > 0 ) {
  return 1;
 } else {
  return 0;
 }
}


sub dump_rdf {
 foreach ( keys %reg_sub_f ) {
  print "\n== Reg Offset: $_ ==\n";
  my $all_sub_fld = $reg_sub_f{$_};
  foreach my $xx (@$all_sub_fld) {
    print "==> $xx->[0] $xx->[1] $xx->[2] $xx->[3] $xx->[4] <==\n";
  }
 }
}


sub get_width {
#my $rangs = @_;
 my $rangs = $_[0];
#print "==== $rangs ====\n";
 my @ranga = split(':', $rangs);
 my $msb   = $ranga[0];
 my $lsbx  = $ranga[1];
 my $width = $msb - $lsbx + 1;
 return ($width);
}

sub get_lsb {
#my $rangs = @_;
 my $rangs = $_[0];
 my @ranga = split(':', $rangs);
 my $lsbb  = $ranga[1];
 return ($lsbb);
}


sub gen_zero {
 my $len_req = $_[0];
 my $zro_str = "";
 for (my $k = 0 ; $k < $len_req ; $k++) {
  $zro_str .= "0";
 }
 return $zro_str;
}


sub get_ofst {
 my $str = $_[0];
 my $len = length($str);

 if( $addr_bus_widt > 12 ) {
  my $dif = 4 - $len; 
  my $zro = gen_zero ($dif);
  $str = $zro.$str;
 } else {
  if( $addr_bus_widt >  8 ) {
   my $dif = 3 - $len; 
   my $zro = gen_zero ($dif);
   $str = $zro.$str;
  } else {
   if( $addr_bus_widt >  4 ) {
    my $dif = 2 - $len; 
    my $zro = gen_zero ($dif);
    $str = $zro.$str;
   }
  }
 }
 return $str;
}



# remove any field start with ',"' and end with '",'
# or
#                  start with ',"' and end with '"'

# 1,2,3,"asdfa , asd",4,5
# 1,2,3,,4,5
# only remove one "XXX" field for the time being, TBD
sub rm_dq {
 my $str = $_[0];

#print "\n==> $str, ";

 my $tmp0 = $str;

 # keep head1 part
 if( $tmp0 =~ /,\"/ ) {
  $tmp0 =~ s/,\".*$/,/;
  if( $str =~ /\"\,/ ) {
   my $tmp1 = $str;
   $tmp1 =~ s/^.*,\"//;
   $tmp1 =~ s/.*\",/,/;
   $str = $tmp0.$tmp1;
   return $str;
  } else {
#  print "\n==> $str == $tmp0\n";
   if( $str =~ /\"$/ ) {
#   $str = $tmp0.",";
    $str = $tmp0;
    return $str;
   } else {
    die "rm_dq parsing error, line: $str";
   }
  }
 } else {
  return $str;
 }
}

