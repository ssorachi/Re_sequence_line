#! /bin/sh
#$ -S /bin/sh
#$ -cwd

export PATH=/lustre7/home/s-saiga/miniconda3/envs/re_sequence_line/bin:${PATH}
bwa_PATH=/lustre7/home/s-saiga/miniconda3/envs/re_sequence_line/bin/bwa-mem2
samtools_PATH=/lustre7/home/s-saiga/miniconda3/bin/samtools
export PYTHONPATH=$PYTHONPATH:/lustre7/home/s-saiga/miniconda3/envs/Principal_component_analysis/lib/python3.9/site-packages
#-----------------------------------------------------------------------------------------------------------------------------------------------------------
#alignmentするやつが書かれたファイル(xxx \t xxx_1.fastq.gz \t xxx_2.fastq.gz)
alignment_txt=xxx.txt
#リファレンスfastaのフルパス
reference_fasta=/xxx/public.fasta
#bamを染色体ごとに分割しないのならば１、するのならば２を選択
choice=1
#使うcpuの数
used_cpu=8
#-----------------------------------------------------------------------------------------------------------------------------------------------------------
#前処理
dir_name=`echo ${alignment_txt}|sed -e "s/.*\\///"`
dir_name=`echo ${dir_name}|sed -e "s/\.txt//"`

mkdir ${dir_name}
cd ${dir_name}

#基準配列の下ごしらえ
echo "Preparation reference..."
ln -s ${reference_fasta}
if [ -e ${reference_fasta}.bwt.2bit.64 ]; then
  echo "File exists."
else
  bwa-mem2 index ${reference_fasta}
fi
echo "finish"

#pythonで実行するテキストファイルの作成
python3 ../script/output_txt.py ${alignment_txt} ${reference_fasta}

#並行処理
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

#後処理
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

#fot文
  for i in ${sort_bam_file}
  do
  python3 ../../script/bam_selection.py ../${Reference_fasta_fai}.fai ${i}
  bam_name=`echo ${i}|sed -e "s/.*\\///"`
  #並行処理
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
