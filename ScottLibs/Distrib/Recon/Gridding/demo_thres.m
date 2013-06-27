clc; clear all; close all;
load('bf_vol');

c = b>0.0003;

c = bwareaopen(c,20,4);

imslice(b.*c);

