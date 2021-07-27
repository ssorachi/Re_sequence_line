#! /bin/sh
#$ -S /bin/sh
#$ -cwd

export PATH=###Please enter your conda pass###:${PATH}
bwa_PATH=###Please enter your bwa-mem2 pass###
samtools_PATH=###Please enter your samtools pass###
export PYTHONPATH=$PYTHONPATH:###Please enter your PYTHONPATH###
#-----------------------------------------------------------------------------------------------------------------------------------------------------------
#Input fastq.gz to txt file (ex ... xxx \t xxx_1.fastq.gz \t xxx_2.fastq.gz)
alignment_txt=xxx.txt
#Reference fasta
reference_fasta=/xxx/public.fasta
#Select 1 if you do not divide bam into chromosomes, or 2 if you do.
choice=x  #1 or 2
#used cpu
used_cpu=8
#-----------------------------------------------------------------------------------------------------------------------------------------------------------
dir_name=`echo ${alignment_txt}|sed -e "s/.*\\///"`
dir_name=`echo ${dir_name}|sed -e "s/\.txt//"`

mkdir ${dir_name}
cd ${dir_name}

echo "Preparation reference..."
ln -s ${reference_fasta}
if [ -e ${reference_fasta}.bwt.2bit.64 ]; then
  echo "File exists."
else
  bwa-mem2 index ${reference_fasta}
fi
echo "finish"

python3 ../script/output_txt.py ${alignment_txt} ${reference_fasta}

echo "make sam"
cat make_sam.txt|xargs -P${used_cpu} -I % sh -c %
echo "finish"

echo "make pre.bam"
cat sam_to_prebam.txt|xargs -P${used_cpu} -I % sh -c %
rm *sam
echo "finish"

echo "make marge.bam"
cat prebam_to_mergebam.txt|xargs -P${used_cpu} -I % sh -c %
rm *pre.bam
echo "finish"

echo "make sort.bam"
cat mergebam_to_sortbam.txt|xargs -P${used_cpu} -I % sh -c %
rm *marge.bam
echo "finish"

echo "make bai"
cat sortbam_to_bai.txt|xargs -P${used_cpu} -I % sh -c %
echo "finish"

mkdir sort_bam_bai_pass
mv *.sort.bam sort_bam_bai_pass
mv *.bai sort_bam_bai_pass

if [ ${choice} = 1 ]; then
  echo "do not bam selection"
else
  echo "bam selection"
  echo 'Get the name of the chromosome...'
  Reference_fasta_fai=`echo ${reference_fasta}|sed -e "s/.*\\///"`
  if [ -e ${Reference_fasta_fai}.fai ]; then
    echo "Reference fai file exists."
  else
    samtools faidx ${Reference_fasta_fai}
    echo "finish"
  fi
  mkdir bam_selection_result
  cd bam_selection_result
  sort_bam_file=`ls ../sort_bam_bai_pass/*.bam`

  for i in ${sort_bam_file}
  do
  python3 ../../script/bam_selection.py ../${Reference_fasta_fai}.fai ${i}
  bam_name=`echo ${i}|sed -e "s/.*\\///"`

  echo "make selection ${bam_name}..."
  cat bam_selection.txt|xargs -P${used_cpu} -I % sh -c %

  cat bam_to_bai.txt|xargs -P${used_cpu} -I % sh -c %
  echo 'finish'
  done

  mkdir selection_bam_bai_pass
  mv *.bam selection_bam_bai_pass
  mv *.bai selection_bam_bai_pass

  cd ..
fi

cd ..
