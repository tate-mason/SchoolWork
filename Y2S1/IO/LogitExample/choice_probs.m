function [choice_prob]=choice_probs(sig, d, delta)

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

%CALC EXP(UTILITY) FOR EACH CONSUMER/PRODUCT AT PARAMETERS
choice_prob_tmp=exp(delta+sig_hp.*X(:,2).*draws+sig_mpg.*X(:,3).*draws+sig_fuel.*X(:,4).*draws);

%CALCULATE THE DENOMINATOR FOR EACH CONSUMER AND THEN THE CHOICE
%PROBABILITY FOR EACH CONSUMER/PRODUCT AT PARAMETERS
choice_prob=[];
for y=1995:2000
    choice_prob_tmp2=choice_prob_tmp;
    choice_prob_tmp2(year~=y,:)=[];
    denom=repmat(sum(choice_prob_tmp2,1), size(choice_prob_tmp2,1),1);
    choice_prob=[choice_prob; choice_prob_tmp2./(1+denom)];
end    
end

