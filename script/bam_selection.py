#!/usr/bin/env python
# coding: UTF-8

import sys
import re
args = sys.argv
fasta_fai = args[1]
bam_file = args[2]
#----------------------------------------------------------------------------------------------------------------------------------------
z = open('bam_selection.txt',mode='w')
y = open('bam_to_bai.txt',mode='w')
a = open(fasta_fai,'r')
bam_pass = re.sub('\S+/','',bam_file)

while True:
    line = a.readline()
    if line:
        list = line.split()
        chr_name = list[0]
        z.write('samtools view -@ 10 -b '+bam_file+' '+chr_name+'> '+chr_name+'_'+bam_pass+'\n')
        y.write('samtools index '+chr_name+'_'+bam_pass+'\n')
    else:
        break
