/*Dataset*/
data exp_design;
array loc{5} (0.01 0 0.05 0.02 0.03);
array pr{4} (0.01 0 -0.01 -0.03);
array exp{2} (0.02 0.0);
array O{4} (0 0.01 0.02 0.04);
do i=1 to 5;
	*do j=15 to 30 by 5;
		do k=1 to 2;
			do l=1 to 4;
			Location=i;
			Price=rand("Integer",1,4);
			Experience=k;
			Other=l;
			RR=loc{i}+(pr{Price})+exp{k}+o{l}+0.01;
			output;
			end;
		end;
	*end;
end;
keep Location Price Experience Other RR;
run;

proc glmpower data = exp_design; 
	*Three class variables; 
	class location experience other; 
	*Only main effects for now;
	model RR = location price experience other; 
	contrast 'Experience 2  vs. Experience 1' experience 1 -1;  
	contrast 'Location 2 vs. Location 1' location 0 1 -1 0 0;
	contrast 'Price 1 vs. Price 2' price 1 -1 0 0;
	contrast 'Other  1 vs. Other 2'  Other 1 0 0 -1; 
	POWER  /*THIS IS THE ONLY PART YOU NEED TO WORRY ABOUT*/
		alpha = 0.0125 
		STDDEV = 0.099 /*Mean Square Error = MSE^0.5*/
		NTOTAL = .  /*TOTAL OBSERVATIONS IN THE STUDY*/ 
		POWER  = .80;  
	run; 
quit; 
/*Import data and create random sample*/
proc surveyselect data=orion.rduch
	method=srs n=1200 out=SRS;
	title 'Zipline';
run;
/*Create datasets that matches the sample size*/
data stacked;
	set exp_design;
	do rep = 1 to 30;
	output;
	end;
run;
/*Merge datasets*/
Data new_zip;
Set stacked;
Seqno = _N_;
Run;
data new_srs;
set srs;
Seqno = _N_;
run;
proc sql;
create table final as
select * 
from new_srs as s, new_zip as z
where s.seqno=z.seqno;
quit;

data final;
set final;
drop VAR1 long lat rep seqno;
run;

proc export data=final
    outfile='C:\Users\conne\Documents\My SAS Files\DOE HW1 Experiment Design.csv'
    dbms=csv
    replace;
run;
