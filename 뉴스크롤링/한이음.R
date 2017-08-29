###########crawling finance data
#install.packages("lubridate")
library(lubridate)
library(rvest)
library(stringr)
library(SnowballC)
library(dplyr)
library(janeaustenr)
library(tidytext)

#가격
#https://www.google.com/finance/historical?cid=821222166553443&startdate= Apr+7 %2C+ 2015 &enddate= May+3 %2C+ 2017 &num= 200
#https://www.google.com/finance/historical?cid=821222166553443&startdate= Jan+1 %2C+ 2017 &enddate= May+17 %2C+ 2017 &num= 200
startdate<-"2015/08/10"
enddate<-"2017/08/12"
month<-c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
startyear<-as.numeric(str_sub(startdate,1,4))
startmonth<-month[as.numeric(str_sub(startdate,6,7))]
startday<-as.numeric(str_sub(startdate,9,10))
endyear<-as.numeric(str_sub(enddate,1,4))
endmonth<-month[as.numeric(str_sub(enddate,6,7))]
endday<-as.numeric(str_sub(enddate,9,10))
num<-200
start<-0
url<-"https://www.google.com/finance/historical?cid=821222166553443&startdate="
continue <- TRUE
table<-data.frame()

while(continue)
{
    url1<-url%>%paste(.,startmonth,"+",startday,"%2C+",startyear,"&enddate=",endmonth,"+",endday,"%2C+",endyear,"&num=",num,"&start=",start,sep="")
    table_url<-read_html(url1)%>%html_nodes("div#prices")%>%html_nodes(".gf-table.historical_price")
    plus<-html_table(table_url)[[1]]
    for(i in 2:6) plus[,i]<-as.numeric(gsub(",","",plus[,i]))
    table<-rbind(table,plus)
    if(nrow(plus)<200) continue <- FALSE
    start<-start+num
}

table_month<-factor(str_sub(table$Date,1,3),levels = month,labels=1:12)
table_day<-str_sub(table$Date,5,6)
table_day<-ifelse(str_sub(table_day,2)==",",str_sub(table_day,1,1),table_day)
table_year<-str_trim(str_sub(table$Date,8,12))

date<-as.Date(paste(table_year,table_month,table_day),format="%Y%m%d")
table_result<-cbind(date,table[,2:6])
date20170811<-c(table_result$Close,0)
date20170810<-c(0,table_result$Close)
updown<-ifelse(date20170810-date20170811>0,"up","down")
updown[1]<-NA
updown<-updown[1:496]
updown<-factor(updown,levels=c("down","up"))
table_result<-cbind(table_result,updown)
table_result
table(table_result$updown)
#similar proportion

#####python news data
python<-read.csv("/Users/jinseokryu/Desktop/한이음/newscrawling1/result.csv",stringsAsFactors = FALSE)
python<-python[-89,]
python$date<-as.Date(python$date,format="%y-%m-%d")
dim(python)
head(python)

######merge python crawling data and finance data
merge_table <- merge(x = table_result,    y = python,   by = 'date',   all = TRUE)
#View(merge_table)
total_count<-nrow(merge_table)
for (keep in 1:total_count){
    if(!is.na(merge_table$Close[keep])){
        save_date<-merge_table$date[keep]
        merge_table$before[keep]<-0
    }
    else{
        merge_table$before[keep]<-save_date-merge_table$date[keep]
        merge_table$date[keep]<-save_date
    }
}
#중요테이블
head(merge_table)

###########news data with adjusted date
new<-merge_table[,c(1,10,11,12)]
news<-merge(x = new,    y =table_result[,c(1,7)],   by = 'date')
only_news<-news[complete.cases(news),]

###########adjusted finance data(이 날짜에 뉴스가 있나?? -> 뉴스가 있으면 0, 없으면 1)
head(test<-merge_table[,c('date','url')])
test$isnews<-ifelse(is.na(test$url),0,1)
is_news<-test[,c(1,3)]
#중요테이블
is_news_finance<-merge(table_result,is_news,by='date',all.x = TRUE)


###########parsing the news data
#install.packages("KoNLP")
#install.packages("tm")
library(KoNLP)
library(tm)

#긍부정사전을 만들어야하나...ㅠ
######단어집
f_pos = read.table("/Users/JinseokRyu/Desktop/한이음/dictionary/positive-words-ko-v2.txt")
f_neg = read.table("/Users/JinseokRyu/Desktop/한이음/dictionary/negative-words-ko-v2.txt")

colnames(f_pos)<-"POS"
colnames(f_neg)<-"NEG"

## Checking user defined dictionary!

useSejongDic()
## Backup was just finished!
## 370957 words dictionary was built.

doc<-only_news$article
#숫자," 제거
doc<-gsub("\\d+","",doc)
doc<-gsub('"',"",doc)
doc<-gsub('‘',"",doc)
doc<-gsub('’',"",doc)
doc<-gsub('“',"",doc)
doc<-gsub('”',"",doc)
doc<-gsub("'","",doc)
doc<-gsub(".%","",doc)
doc<-gsub("%","",doc)


head(doc)
#기호 제거
data2<-sapply(doc,extractNoun)

document_label<-paste("documentation",1:585)
names(data2)<-document_label

docs.corp<-Corpus(VectorSource(data2))

#색인어 추출함수
konlp_tokenizer <- function(doc){
    extractNoun(doc)
}


# weightTfIdf 함수 말고 다른 여러 함수들이 제공되는데 관련 메뉴얼을 참고하길 바란다.
pos_dtmat<-DocumentTermMatrix(docs.corp,control = list(tokenize=konlp_tokenizer,
wordLengths=c(5,Inf),
dictionary=as.character(f_pos$POS)))
pos_num<-apply(pos_dtmat,1,sum)
neg_dtmat<-DocumentTermMatrix(docs.corp,control = list(tokenize=konlp_tokenizer,
wordLengths=c(5,Inf),
dictionary=as.character(f_neg$NEG)))
neg_num<-apply(neg_dtmat,1,sum)

pos_neg_news_test<-cbind(is_news_finance[is_news_finance$isnews==1,],pos_num,neg_num)
pos_neg_news<-merge(table_result,pos_neg_news_test)
pos_neg_news$isnews<-ifelse(is.na(pos_neg_news$isnews),0,pos_neg_news$isnews)
pos_neg_news$pos_num<-ifelse(is.na(pos_neg_news$pos_num),0,pos_neg_news$pos_num)
pos_neg_news$neg_num<-ifelse(is.na(pos_neg_news$neg_num),0,pos_neg_news$neg_num)

pos_article<-ifelse(pos_neg_news$pos_num>pos_neg_news$neg_num,1,0)
neg_article<-ifelse(pos_neg_news$pos_num<pos_neg_news$neg_num,1,0)
pos_neg_news_num<-cbind(pos_neg_news,pos_article,neg_article)

#이것도.....;;별로
#Accuracy : 0.4987


library(reshape2)
totals<-group_by(pos_neg_news_num,date)%>%
summarise(.,pos_num=sum(pos_num),neg_num=sum(neg_num),
pos_article=sum(pos_article),neg_article=sum(neg_article))
last_result<-merge(table_result,totals)

############################################
##########################################
##########################################
#나이브 베이즈 실패!!!
# # weightTfIdf 함수 말고 다른 여러 함수들이 제공되는데 관련 메뉴얼을 참고하길 바란다.
# dtmat<-DocumentTermMatrix(docs.corp,control = list(tokenize=konlp_tokenizer,
#                           wordLengths=c(5,Inf)))
# my_dic<-findFreqTerms(dtmat,10)
# dtmat2<-DocumentTermMatrix(docs.corp,control = list(tokenize=konlp_tokenizer,
#                                                    wordLengths=c(5,Inf),
#                                                    dictionary=my_dic))
# inspect(dtmat2)
# dtmat2_train<-dtmat2[flag==1,]
# dtmat2_test<-dtmat2[flag==2,]
#
#
# convert_counts <- function(x) {
#   x <- ifelse(x >0, x,0)
# #  x <- factor(x,levels=c(0,1),labels=c("no","yes"))
#   return(x)
# }
#
# final_train <- apply(dtmat2_train, MARGIN = 2, convert_counts)
# final_test <- apply(dtmat2_test, MARGIN = 2, convert_counts)
#
#
# ######33전처리 끝#########3
# #######3모델링 ##############
# # install.packages("e1071")
# library(e1071)
#
# sms_classifier <- naiveBayes(final_train, trainset$updown)
#
# ## 모델 성능 평가#
#
# pred <- predict(sms_classifier, final_test)
#
# library(caret)
#
# confusionMatrix(pred, testset$updown, dnn=c('predcited', 'actual'))
# #Accuracy : 0.5714
# #사용못하겠넹...ㅠ
# ##############################################################
# #나이브베이즈 안쓰고 직접 코딩해서 만든 것... 점수매기기
# only_news$updown_numeric<-ifelse(only_news$updown=="up",1,-1)
# test<-cbind(dtmat2,only_news$updown_numeric)
# dtmat2<-as.matrix(dtmat2)
# new_dtmat<-dtmat2
#
# for(i in 1:nrow(dtmat2)){
#   for(j in 1:ncol(dtmat2)){
#     new_dtmat[i,j]<-dtmat2[i,j]*only_news$updown_numeric[i]
#   }
# }
#
# new_dtmat2<-apply(new_dtmat,1,prop.table)
# words_score<-apply(new_dtmat2,1,sum)
#
# docs_score<-dtmat2%*%words_score
# boxplot(docs_score)
# median(docs_score)
# pred<-ifelse(docs_score>160,"up","down")
# updown_news<-ifelse(only_news$updown_numeric==-1,"down","up")
# total<-cbind(docs_score,pred,updown_news)[,2:3]
# sum(total[,1]==total[,2])/nrow(total)
# #0.5690608
# #설명력이 안높음…
# #이것도 사용못하겠네…ㅠ

############################################
##########################################
##########################################
