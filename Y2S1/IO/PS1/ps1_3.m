cd('~/SchoolWork/Y2S1/IO/PS1/')
clear;

data = readtable('IRI.csv');

year = data(:, 1);
month = data(:, 2);
store_id = data(:, 3);
week_id = data(:, 4);
market_name = data(:, 5);


