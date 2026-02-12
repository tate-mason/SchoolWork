function [xi, market_share, beta, delta]=contract_map(sig, d)

%INITIALIZE DATA
X=d.X;
sj=d.sj;
draws=d.draws;
iv=d.iv;
year=d.year;
n=d.n;
price=d.price;

%GET SIG PARAMETERS OUT
sig_hp=exp(sig(1));
sig_mpg=exp(sig(2));
sig_fuel=exp(sig(3));

crit=1; %CRITICAL VALUE INITIAL
delta0=zeros(size(sj,1),1); %INITIAL DELTA
delta=delta0; 

while crit>.00001

%CALC EXP(UTILITY) FOR EACH CONSUMER/PRODUCT
choice_prob_tmp=exp(delta+sig_hp.*X(:,2).*draws+sig_mpg.*X(:,3).*draws+sig_fuel.*X(:,4).*draws);

%CALCULATE THE DENOMINATOR FOR EACH CONSUMER AND THEN THE CHOICE
%PROBABILITY FOR EACH CONSUMER/PRODUCT
choice_prob=[];
for y=1995:2000
    choice_prob_tmp2=choice_prob_tmp;
    choice_prob_tmp2(year~=y,:)=[];
    denom=repmat(sum(choice_prob_tmp2,1), size(choice_prob_tmp2,1),1);
    choice_prob=[choice_prob; choice_prob_tmp2./(1+denom)];
end    

%CALCULATE MODEL PREDICTED MARKET SHARE
market_share=sum(choice_prob,2)./n;

%DIFFERENCE BETWEEN OLD DELTA AND NEW DELTA
delta_old=delta;
delta=delta_old+log(sj)-log(market_share);
crit=max(abs(sj-market_share));
end

%2SLS IV ESTIMATES%
beta=([X,iv]'*[X,price])^(-1)*([X,iv]'*delta);

xi=delta-[X,price]*beta;
end

