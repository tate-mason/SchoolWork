cd('C:/Users/timot/OneDrive/Academics/Industrial/LogitExample');
clear;

%LOAD DATA%
car_panel=csvread('cars2.csv',1,0);

%CREATE VARIABLES%
code=car_panel(:,1);
orig=car_panel(:,2);
firm_id=car_panel(:,3);
year=car_panel(:,4);
price=car_panel(:,5);
quantity=car_panel(:,6);
hp=car_panel(:,7);
clength=car_panel(:,8);
width=car_panel(:,9);
csize=car_panel(:,10);
weight=car_panel(:,11);
fuel=car_panel(:,12);
mpg=car_panel(:,13);
fuel_price=car_panel(:,14);
segment=car_panel(:,15);
steel_price=car_panel(:,16);
brand_id=car_panel(:,17);
model_id=car_panel(:,18);

%% LOGIT

%GENERATE MARKET SIZE (AVE 10% OVER SAMPLE)%
totQ=ones(size(car_panel,1),1).*sum(quantity);
M=totQ/(6*.1);

%MARKET SHARE%
sj=quantity./M;

%CREATE OUTSIDE SHARE%

%SUM SHARES BY YEAR%
create_index=unique(year, 'rows');
index=(1:length(create_index))';
[tf,loc]=ismember(year, create_index, 'rows');
indices=[index(loc(tf),:)];
inside_share_tmp=[accumarray(indices,year,[], @mean),accumarray(indices,sj,[], @sum)];

%MERGE BACK INTO MAIN DATA SET%
[tf,loc] = ismember(year, inside_share_tmp(:,1) ); 
inside_share=inside_share_tmp(loc(tf),2); 

s0=1-inside_share;

%CREATE IV%
iv=csize.*steel_price;

%CREATE DEP VAR%
DV=log(sj)-log(s0);

%CREATE Xs (CHARACTERISTICS)%
non_euro=orig>1;

small=segment==1;
compact=segment==2;
sedan=segment==3;
luxery=segment==4;
mini=segment==5;

X=[ones(size(hp,1),1), hp, mpg, fuel, non_euro, small, sedan, luxery, mini];

%OLS ESTIMATES%
beta1=([X,price]'*[X,price])^(-1)*([X,price]'*DV);

%STANDARD ERRORS%
sig_sq=var(DV-[X,price]*beta1);
std_err1=sqrt(diag(sig_sq.*([X,price]'*[X,price])^(-1)));

%POSTESTIMATION%
alpha1=beta1(end);
oelas1=alpha1.*price.*(1-sj);

histogram(oelas1)

%IV (2SLS) ESTIMATES%
beta2=([X,iv]'*[X,price])^(-1)*([X,iv]'*DV);

%STANDARD ERRORS%
sig_sq=var(DV-[X,price]*beta2);
std_err2=sqrt(diag(sig_sq.*([X,iv]'*[X,price])^(-1)*([X,iv]'*[X,iv])*([X,price]'*[X,iv])^(-1)));

%POSTESTIMATION%
alpha2=beta2(end);
oelas2=alpha2.*price.*(1-sj);

histogram(oelas2)

%% NESTED LOGIT%

%CREATE CONDTIONAL SHARE%

%SUM SHARES BY YEAR/SEGMENT%
create_index=unique([year,segment], 'rows');
index=(1:length(create_index))';
[tf,loc]=ismember([year, segment], create_index, 'rows');
indices=[index(loc(tf),:)];
inside_share_tmp=[accumarray(indices,indices,[], @mean),accumarray(indices,quantity,[], @sum), accumarray(indices,quantity>0,[], @sum)];

%MERGE SEGMENT QUANT BACK IN TO MAIN DATA%
[tf,loc] = ismember(indices, inside_share_tmp(:,1) ); 
segment_quant=inside_share_tmp(loc(tf),2); 

%CONDITIONAL SHARE%
sjg=quantity./segment_quant;
log_sjg=log(sjg);

%CREATE IV FOR CONDITIONAL SHARE%
iv2=inside_share_tmp(loc(tf),3); 

%NEW CHARACTERISTICS MATRIX%
X=[ones(size(hp,1),1), hp, mpg, fuel, non_euro];

%NESTED LOGIT IV ESTIMATES%
beta3=([X,iv,iv2]'*[X,price,log_sjg])^(-1)*([X,iv, iv2]'*DV);

%STANDARD ERRORS
sig_sq=var(DV-[X,price, log_sjg]*beta3);
std_err3=sqrt(diag(sig_sq.*([X,iv, iv2]'*[X,price, log_sjg])^(-1)*([X,iv, iv2]'*[X,iv, iv2])*([X,price, log_sjg]'*[X,iv, iv2])^(-1)));

%POESTESTIMATION%
alpha3=beta3(end-1);
sig1=beta3(end);
oelas3=alpha3.*1./(1-sig1).*price.*(1-sig1.*sjg-1.*(1-sig1).*sj);
histogram(oelas3)

%% SUBSTITUTION and MARKET POWER

%CREATE RANKS OF BRAND%
create_index=unique([code, brand_id, model_id], 'rows');
index=(1:length(create_index))';
[tf,loc]=ismember([code, brand_id, model_id], create_index, 'rows');
indices=[index(loc(tf),:)];
tot_quant_bm=[accumarray(indices,indices,[], @mean),accumarray(indices,quantity,[], @sum),accumarray(indices,segment,[], @mean)];

seg_rank_tmp=[];

for s=1:max(segment)
    quant_bm_temp=tot_quant_bm;
    quant_bm_temp(quant_bm_temp(:,3)~=s,:)=[];
    quant_bm_temp=sortrows(quant_bm_temp,2, 'descend');
    quant_bm_temp(:,4)=(1:length(quant_bm_temp))';
    seg_rank_tmp=[seg_rank_tmp;quant_bm_temp];
end

%MERGE BACK IN TO MAIN DATA%
[tf,loc] = ismember(indices, seg_rank_tmp(:,1) ); 
seg_rank=seg_rank_tmp(loc(tf),4);
seg_quant=seg_rank_tmp(loc(tf),2);


for y=min(year):max(year)
    %SUBSET DATA BU YEAR%
    shares=[year, seg_rank, sj, sjg, price, code, brand_id, model_id, segment, firm_id];
    shares=sortrows(shares, [6,7,8]);
    %shares(shares(:,1)~=y | shares(:,2)>5,:)=[];
    shares(shares(:,1)~=y,:)=[];
    sj_y=shares(:,3);
    sjg_y=shares(:,4);
    price_y=shares(:,5);
    firm_y=shares(:,10);
    
    %CREATE EMPTY MATRICES%
    subs_mat_y(:,:)=zeros(length(sj_y), length(sj_y));
    elas_mat_y(:,:)=zeros(length(sj_y), length(sj_y));
    own_mat_y1(:,:)=eye(length(sj_y), length(sj_y));
    own_mat_y2(:,:)=eye(length(sj_y), length(sj_y));
    own_mat_y3(:,:)=ones(length(sj_y), length(sj_y));
    div_mat_y=zeros(length(sj_y), length(sj_y));
    % FILL MATRICES WITH DERIVATIVES AND ELACXTICITIES
    for i=1:length(sj_y)
        for j=1:length(sj_y)
            if i==j
                subs_mat_y(j,i)=alpha3*sj_y(j)*1/(1-sig1)*(1-sig1*sjg_y(j)-(1-sig1)*sj_y(j));
                elas_mat_y(j,i)=alpha3*sj_y(j)*1/(1-sig1)*(1-sig1*sjg_y(j)-(1-sig1)*sj_y(j))*price_y(j)/sj_y(j);
                own_mat_y2(j,i)=1;
            elseif shares(i,9)~=shares(j,9)
                subs_mat_y(j,i)=-1*alpha3*sj_y(j)*sj_y(i);
                elas_mat_y(j,i)=-1*alpha3*sj_y(j)*sj_y(i)*price_y(i)/sj_y(j);
                own_mat_y2(j,i)=shares(i,10)==shares(j,10);
            elseif shares(i,9)==shares(j,9)
                subs_mat_y(j,i)=-1*alpha3*(sj_y(i))*(sj_y(j)+sig1/(1-sig1)*sjg_y(j)); 
                elas_mat_y(j,i)=-1*alpha3*(sj_y(i))*(sj_y(j)+sig1/(1-sig1)*sjg_y(j))*price_y(i)/sj_y(j);
                own_mat_y2(j,i)=shares(i,10)==shares(j,10);
            end
        end
    end
    % FILL MAT WITH DIVERSION RATIOS
    for i=1:length(sj_y)
        for j=1:length(sj_y)
            if i==j
                div_mat_y(j,i)=0;
            else
                div_mat_y(j,i)=subs_mat_y(j,i)/abs(subs_mat_y(i,i));
            end
        end
    end
 
% STORE MATS BY YEAR    
    if y==1995
        subs_mat95=subs_mat_y;
        elas_mat95=elas_mat_y;
        own_mat951=own_mat_y1;
        own_mat952=own_mat_y2;
        own_mat953=own_mat_y3;
        div_rat95=div_mat_y;
        shares95=sj_y;
        price95=price_y;
    elseif y==1996
        subs_mat96=subs_mat_y;
        elas_mat96=elas_mat_y;
        own_mat961=own_mat_y1;
        own_mat962=own_mat_y2;
        own_mat963=own_mat_y3;
        div_rat96=div_mat_y;
        shares96=sj_y;
        price96=price_y;
    elseif y==1997
        subs_mat97=subs_mat_y;
        elas_mat97=elas_mat_y;
        own_mat971=own_mat_y1;
        own_mat972=own_mat_y2;
        own_mat973=own_mat_y3;
        div_rat97=div_mat_y;
        shares97=sj_y;
        price97=price_y;
    elseif y==1998
        subs_mat98=subs_mat_y;
        elas_mat98=elas_mat_y;
        own_mat981=own_mat_y1;
        own_mat982=own_mat_y2;
        own_mat983=own_mat_y3;
        div_rat98=div_mat_y;
        shares98=sj_y;
        price98=price_y;
    elseif y==1999
        subs_mat99=subs_mat_y;
        elas_mat99=elas_mat_y;
        own_mat991=own_mat_y1;
        own_mat992=own_mat_y2;
        own_mat993=own_mat_y3;
        div_rat99=div_mat_y;
        shares99=sj_y;
        price99=price_y;
    elseif y==2000    
        subs_mat00=subs_mat_y;
        elas_mat00=elas_mat_y;
        own_mat001=own_mat_y1;
        own_mat002=own_mat_y2;
        own_mat003=own_mat_y3;
        div_rat00=div_mat_y;
        shares00=sj_y;
        price00=price_y;
    end
    clear subs_mat_y elas_mat_y own_mat_y1 own_mat_y3 own_mat_y2 div_mat_y
end

%CREATE MARK UPS
mark_up95_1=-1.*(shares95./price95)'*(own_mat951.*subs_mat95)^(-1);
mark_up95_2=-1.*(shares95./price95)'*(own_mat952.*subs_mat95)^(-1);                
mark_up95_3=-1.*(shares95./price95)'*(own_mat953.*subs_mat95)^(-1); 

mark_up96_1=-1.*(shares96./price96)'*(own_mat961.*subs_mat96)^(-1);
mark_up96_2=-1.*(shares96./price96)'*(own_mat962.*subs_mat96)^(-1);                
mark_up96_3=-1.*(shares96./price96)'*(own_mat963.*subs_mat96)^(-1); 

mark_up97_1=-1.*(shares97./price97)'*(own_mat971.*subs_mat97)^(-1);
mark_up97_2=-1.*(shares97./price97)'*(own_mat972.*subs_mat97)^(-1);                
mark_up97_3=-1.*(shares97./price97)'*(own_mat973.*subs_mat97)^(-1); 

mark_up98_1=-1.*(shares98./price98)'*(own_mat981.*subs_mat98)^(-1);
mark_up98_2=-1.*(shares98./price98)'*(own_mat982.*subs_mat98)^(-1);                
mark_up98_3=-1.*(shares98./price98)'*(own_mat983.*subs_mat98)^(-1); 

mark_up99_1=-1.*(shares99./price99)'*(own_mat991.*subs_mat99)^(-1);
mark_up99_2=-1.*(shares99./price99)'*(own_mat992.*subs_mat99)^(-1);                
mark_up99_3=-1.*(shares99./price99)'*(own_mat993.*subs_mat99)^(-1); 

mark_up00_1=-1.*(shares00./price00)'*(own_mat001.*subs_mat00)^(-1);
mark_up00_2=-1.*(shares00./price00)'*(own_mat002.*subs_mat00)^(-1);                
mark_up00_3=-1.*(shares00./price00)'*(own_mat003.*subs_mat00)^(-1); 

% AVERAGE MARK UPS
mark_ups(:,1)=[mean(mark_up95_1); mean(mark_up96_1);mean(mark_up97_1);mean(mark_up98_1);mean(mark_up99_1);mean(mark_up00_1)];
mark_ups(:,2)=[mean(mark_up95_2); mean(mark_up96_2);mean(mark_up97_2);mean(mark_up98_2);mean(mark_up99_2);mean(mark_up00_2)];
mark_ups(:,3)=[mean(mark_up95_3); mean(mark_up96_3);mean(mark_up97_3);mean(mark_up98_3);mean(mark_up99_3);mean(mark_up00_3)];



%% BLP

%CONSUMER DRAWS OF NU. EACH CONSUMER HAS THEIR ONW NU, SO NEED TO REPEAT THAT
%J TIMES FOR EACH YEAR
n=1000;
draws=[];
for y=min(year):max(year)
    hp_y=hp;
    hp_y(year~=y,:)=[];
    draws_tmp=repmat(normrnd(0,1,1, n), size(hp_y,1),1); %nu_i
    draws=[draws; draws_tmp];
end
    
X=[ones(size(hp,1),1), hp, mpg./100, fuel, non_euro];

%GENERATE BLP INSTRUMENTS%
%SUM OF CHARACTERISTICS BY YEAR/SEGMENT%
create_index=unique([year], 'rows');
index=(1:length(create_index))';
[tf,loc]=ismember([year], create_index, 'rows');
indices=[index(loc(tf),:)];
sum_chars_tmp=[accumarray(indices,indices,[], @mean),accumarray(indices,hp,[], @sum), accumarray(indices,mpg./100,[], @sum), accumarray(indices,fuel,[], @sum), accumarray(indices,X(:,1)>0,[], @sum)];

%MERGE SEGMENT QUANT BACK IN TO MAIN DATA%
[tf,loc] = ismember(indices, sum_chars_tmp(:,1) ); 
sum_chars=sum_chars_tmp(loc(tf),2:5); 

%CALCULATE THE AVERAGE OF DEVIATION FROM OTHER PRODS SQUARED=% 
%rc_ivs=((sum_chars(:,1:3)-[hp,mpg./100,fuel])./sum_chars(:,4)).^2;
rc_ivs=((sum_chars(:,1:3)-[hp,mpg./100,fuel])./repmat((sum_chars(:,4)-1),1,size(sum_chars(:,1:3),2))-[hp,mpg./100,fuel]).^2;

%CONDOLIDATE VARIABLES FOR ESTIMATION%
d.X=X;
d.sj=sj;
d.draws=draws;
d.iv=iv;
d.year=year;
d.n=n;
d.price=price;
d.rc_ivs=rc_ivs;


%INITIALIZE FOR ESTIMATION%
x0=0.*[ones(size(rc_ivs,2),1)];
W=eye(size(x0,1), size(x0,1));
max_iter=10000000000000;
options = optimoptions(@fminunc, 'Display', 'iter', 'MaxFunEvals', max_iter, 'OptimalityTolerance', .000000000000000000001);

%TEST OBJ FUNC CALC%
%obj_fun(x0, W, d)

%FIRST STAGE GMM%
efunc=@ (x) obj_fun(x, W,d);
start=x0;
[x,fval2,exitflag,output]=fminunc(efunc, start, options);

%OPTIMAL WEIGHT MATRIX
W=opt_weight(x, d);

%SECOND STAGE ESTIMATION
efunc=@ (x) obj_fun(x, W,d);
start=x;
[x,fval2,exitflag,output]=fminunc(efunc, start, options);

%ESTIMATES IF YOU WANT TO SHORTEN PROGRAM%
%x=[4.1739; -10.5715; -12.3750];


%GET BETA AND ALPHA PARAMS BACK%
[xi, market_share, beta4, delta]=contract_map(x, d);
alpha4=beta4(end);

%% SUBSTITUATION and MARKET POWER FOR ML MODEL

%CALC ELASTICITIES ETC%
%GET CHOICE PROBS FOR EACH DRAW/PRODUCT
[choice_prob]=choice_probs(x, d, delta);

for y=min(year):max(year)
    %SUBSET DATA BU YEAR%
    price_y=price;
    price_y(year~=y,:)=[];
    firm_y=firm_id;
    firm_y(year~=y,:)=[];
    choice_prob_y=choice_prob;
    choice_prob_y(year~=y,:)=[];
    sj_y=sj;
    sj_y(year~=y,:)=[];
    
    %CREATE EMPTY MATRICES%
    subs_mat_y2=zeros(length(sj_y), length(sj_y), n);
    elas_mat_y2=zeros(length(sj_y), length(sj_y),n);
    div_mat_y2=zeros(length(sj_y), length(sj_y),n);
    own_mat_y2_2=zeros(length(sj_y), length(sj_y), n);
    % FILL MATRICES WITH DERIVATIVES AND ELACXTICITIES FOR EACH CONSUMER
    for c=1:n
    for i=1:length(sj_y)
        for j=1:length(sj_y)
            if i==j
                subs_mat_y2(j,i,c)=alpha4*choice_prob_y(j,c)*(1-choice_prob_y(j,c));
                elas_mat_y2(j,i,c)=alpha4*choice_prob_y(j,c)*(1-choice_prob_y(j,c))*price_y(j)/sj_y(j);
                own_mat_y2_2(j,i,c)=1;
            elseif firm_y(i)==firm_y(j) 
                subs_mat_y2(j,i,c)=-1*alpha4*choice_prob_y(j,c)*(choice_prob_y(i,c));
                elas_mat_y2(j,i,c)=-1*alpha4*choice_prob_y(j,c)*(choice_prob_y(i,c))*price_y(i)/sj_y(j);
                own_mat_y2_2(j,i, c)=1;
            elseif firm_y(i)~=firm_y(j) 
                subs_mat_y2(j,i,c)=-1*alpha4*choice_prob_y(j,c)*(choice_prob_y(i,c));
                elas_mat_y2(j,i,c)=-1*alpha4*choice_prob_y(j,c)*(choice_prob_y(i,c))*price_y(i)/sj_y(j);
                own_mat_y2_2(j,i, c)=0;
            end
        end
    end
    end
    
    %AVERAGE ACROSS CONSUMERS TO GET DRIVATIVES AND ELAS
    subs_mat_y3=mean(subs_mat_y2,3);
    elas_mat_y3=mean(elas_mat_y2,3);   
    own_mat_y2_2_2=mean(own_mat_y2_2, 3);
    
    % FILL MAT WITH DIVERSION RATIOS
    for i=1:length(sj_y)
        for j=1:length(sj_y)
            if i==j
                div_mat_y2(j,i)=0;
            else
                div_mat_y2(j,i)=subs_mat_y3(j,i)/abs(subs_mat_y3(i,i));
            end
        end
    end
 
% STORE MATS BY YEAR    
    if y==1995
        subs_mat95=subs_mat_y3;
        elas_mat95=elas_mat_y3;
        div_rat95=div_mat_y2;
        own_mat952=own_mat_y2_2_2;
        shares95=sj_y;
        price95=price_y;
    elseif y==1996
        subs_mat96=subs_mat_y3;
        elas_mat96=elas_mat_y3;
        div_rat96=div_mat_y2;
        own_mat962_2=own_mat_y2_2_2;
        shares96=sj_y;
        price96=price_y;
    elseif y==1997
        subs_mat97=subs_mat_y3;
        elas_mat97=elas_mat_y3;
        div_rat97=div_mat_y2;
        own_mat972=own_mat_y2_2_2;
        shares97=sj_y;
        price97=price_y;
    elseif y==1998
        subs_mat98=subs_mat_y3;
        elas_mat98=elas_mat_y3;
        div_rat98=div_mat_y2;
        own_mat982=own_mat_y2_2_2;
        shares98=sj_y;
        price98=price_y;
    elseif y==1999
        subs_mat99=subs_mat_y3;
        elas_mat99=elas_mat_y3;
        div_rat99=div_mat_y2;
        own_mat992=own_mat_y2_2_2;
        shares99=sj_y;
        price99=price_y;
    elseif y==2000    
        subs_mat00=subs_mat_y3;
        elas_mat00=elas_mat_y3;
        div_rat00=div_mat_y2;
        own_mat002=own_mat_y2_2_2;
        shares00=sj_y;
        price00=price_y;
    end
    clear subs_mat_y elas_mat_y own_mat_y1 own_mat_y3 own_mat_y2 div_mat_y
end

%CREATE MARK UPS
mark_up95_1=-1.*(shares95./price95)'*(own_mat951.*subs_mat95)^(-1);
mark_up95_2=-1.*(shares95./price95)'*(own_mat952.*subs_mat95)^(-1);                
mark_up95_3=-1.*(shares95./price95)'*(own_mat953.*subs_mat95)^(-1); 

mark_up96_1=-1.*(shares96./price96)'*(own_mat961.*subs_mat96)^(-1);
mark_up96_2=-1.*(shares96./price96)'*(own_mat962.*subs_mat96)^(-1);                
mark_up96_3=-1.*(shares96./price96)'*(own_mat963.*subs_mat96)^(-1); 

mark_up97_1=-1.*(shares97./price97)'*(own_mat971.*subs_mat97)^(-1);
mark_up97_2=-1.*(shares97./price97)'*(own_mat972.*subs_mat97)^(-1);                
mark_up97_3=-1.*(shares97./price97)'*(own_mat973.*subs_mat97)^(-1); 

mark_up98_1=-1.*(shares98./price98)'*(own_mat981.*subs_mat98)^(-1);
mark_up98_2=-1.*(shares98./price98)'*(own_mat982.*subs_mat98)^(-1);                
mark_up98_3=-1.*(shares98./price98)'*(own_mat983.*subs_mat98)^(-1); 

mark_up99_1=-1.*(shares99./price99)'*(own_mat991.*subs_mat99)^(-1);
mark_up99_2=-1.*(shares99./price99)'*(own_mat992.*subs_mat99)^(-1);                
mark_up99_3=-1.*(shares99./price99)'*(own_mat993.*subs_mat99)^(-1); 

mark_up00_1=-1.*(shares00./price00)'*(own_mat001.*subs_mat00)^(-1);
mark_up00_2=-1.*(shares00./price00)'*(own_mat002.*subs_mat00)^(-1);                
mark_up00_3=-1.*(shares00./price00)'*(own_mat003.*subs_mat00)^(-1); 

% AVERAGE MARK UPS
mark_ups_blp(:,1)=[mean(mark_up95_1); mean(mark_up96_1);mean(mark_up97_1);mean(mark_up98_1);mean(mark_up99_1);mean(mark_up00_1)];
mark_ups_blp(:,2)=[mean(mark_up95_2); mean(mark_up96_2);mean(mark_up97_2);mean(mark_up98_2);mean(mark_up99_2);mean(mark_up00_2)];
mark_ups_blp(:,3)=[mean(mark_up95_3); mean(mark_up96_3);mean(mark_up97_3);mean(mark_up98_3);mean(mark_up99_3);mean(mark_up00_3)];





