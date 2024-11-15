#!/bin/bash
# From: https://github.com/RosettaCommons/RoseTTAFold

export BLASTMAT=$PIPE_DIR/blast-2.2.26/data/

DATADIR="$CONDA_PREFIX/share/psipred_4.01/data"
echo $DATADIR

i_a3m="$1"
o_ss="$2"

output_dir=$(dirname "$i_a3m")  # we same the tmp files in the same directory as the input a3m file
ID=tmp  # Here we make it simpler than the original script

$PIPE_DIR/csblast-2.2.3/bin/csbuild -i $i_a3m -I a3m -D $PIPE_DIR/csblast-2.2.3/data/K4000.crf -o $output_dir/$ID.chk -O chk

head -n 2 $i_a3m > $output_dir/$ID.fasta
echo $output_dir/$ID.chk > $output_dir/$ID.pn
echo $output_dir/$ID.fasta > $output_dir/$ID.sn

# makemat seems to expect relative path so it's easier to cd to the output directory and then go back to the original directory
cd $output_dir
makemat -P $ID
cd -

psipred $output_dir/$ID.mtx $DATADIR/weights.dat $DATADIR/weights.dat2 $DATADIR/weights.dat3 > $output_dir/$ID.ss
psipass2 $DATADIR/weights_p2.dat 1 1.0 1.0 $i_a3m.csb.hhblits.ss2 $output_dir/$ID.ss > $output_dir/$ID.horiz

(
echo ">ss_pred"
grep "^Pred" $output_dir/$ID.horiz | awk '{print $2}'
echo ">ss_conf"
grep "^Conf" $output_dir/$ID.horiz | awk '{print $2}'
) | awk '{if(substr($1,1,1)==">") {print "\n"$1} else {printf "%s", $1}} END {print ""}' | sed "1d" > $o_ss

rm ${i_a3m}.csb.hhblits.ss2
rm $output_dir/$ID.*
