#!/usr/bin/env python
# coding: UTF-8
# In[11]:

import sys
import re

args = sys.argv
alignment_txt = args[1]
#リファレンスの絶対パス
reference_fasta = args[2]
#----------------------------------------------------------------------------------------------------------------------------------------
#書き込み
a = open(alignment_txt,'r')
f = open('make_sam.txt',mode='w')
g = open('sam_to_prebam.txt',mode='w')
h = open('mergebam_to_sortbam.txt',mode='w')
i = open('sortbam_to_bai.txt',mode='w')
j = open('prebam_to_mergebam.txt',mode='w')

count = 0
sample_name = 'hogehoge'

while True:
    line_1 = a.readline()
    if line_1:
        list_1 = line_1.split()
        if sample_name == list_1[0]:
            count = count + 1
        else:
            all_bam=''
            if count>0:
                for item in range(count):
                    #all_bamを積み上げる。count = count + 1のように。
                    numeric_number=item+1
                    all_bam=all_bam+' '+sample_name+'_'+str(numeric_number)+'pre.bam'
                j.write('samtools merge -f '+sample_name+'_'+'marge.bam'+all_bam+'\n')
                h.write('samtools sort -@ 4 '+sample_name+'_'+'marge.bam '+'-o '+sample_name+'.sort.bam'+'\n')
                i.write('samtools index '+sample_name+'.sort.bam'+'\n')
            count = 1
            sample_name = list_1[0]
        first_read=list_1[1]
        first_read_name=re.sub('\S+/','',first_read)
        second_read=list_1[2]
        second_read_name=re.sub('\S+/','',second_read)
        f.write('bwa-mem2 mem -t 8 '+reference_fasta+' '+list_1[1]+' '+list_1[2]+'>'+list_1[0]+'_'+str(count)+'.sam'+'\n')
        g.write('samtools view -Sb -@ 4 '+list_1[0]+'_'+str(count)+'.sam'+' > '+list_1[0]+'_'+str(count)+'pre.bam'+'\n')
    else:
        break
#最終行を吐き出す
all_bam=''
if count>0:
    for item in range(count):
        numeric_number=item+1
        all_bam=all_bam+' '+sample_name+'_'+str(numeric_number)+'pre.bam'
    j.write('samtools merge -f '+sample_name+'_'+'marge.bam'+all_bam+'\n')
    h.write('samtools sort -@ 4 '+sample_name+'_'+'marge.bam '+'-o '+sample_name+'.sort.bam'+'\n')
    i.write('samtools index '+sample_name+'.sort.bam'+'\n')

a.close()
