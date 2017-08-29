install.packages("xlsx")
install.packages("nnet")
install.packages("rvest")
install.packages("stringr")
library(rvest)
library(stringr)
#가격
#https://www.google.com/finance/historical?cid=821222166553443&startdate= Apr+7 %2C+ 2015 &enddate= May+3 %2C+ 2017 &num= 200
#https://www.google.com/finance/historical?cid=821222166553443&startdate= Jan+1 %2C+ 2017 &enddate= May+17 %2C+ 2017 &num= 200
startdate<-"2016/11/01"
enddate<-"2017/08/01"
month<-c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
startyear<-as.numeric(str_sub(startdate,1,4))
startmonth<-month[as.numeric(str_sub(startdate,6,7))]
startday<-as.numeric(str_sub(startdate,9,10))
endyear<-as.numeric(str_sub(enddate,1,4))
endmonth<-month[as.numeric(str_sub(enddate,6,7))]
endday<-as.numeric(str_sub(enddate,9,10))
num<-200
url<-"https://www.google.com/finance/historical?cid=821222166553443&startdate="
url1<-url%>%paste(.,startmonth,"+",startday,"%2C+",startyear,"&enddate=",endmonth,"+",endday,"%2C+",endyear,"&num=",num,sep="")

table_url<-read_html(url1)%>%html_nodes("div#prices")%>%html_nodes(".gf-table.historical_price")
table<-html_table(table_url)[[1]]
for(i in 2:6) table[,i]<-as.numeric(gsub(",","",table[,i]))
table

library(xlsx)
library(nnet)

df<-data.frame(일자=table$Date,현재지수=table$Close)
df
plot(df$일자,df$현재지수,xlab="일자",ylab="종가")
grid()

getDataSet<-function(item,from,to,size){
    dataframe<-NULL
    to<-to-size+1
    for(i in from:to) {
        start<-i
        end<-start+size-1
        temp<-item[c(start:end)]
        dataframe<-rbind(dataframe,t(temp))
    }
    return(dataframe)
}

INPUT_NODES<-10
HIDDEN_NODES<-INPUT_NODES*2
OUTPUT_NODES<-5
ITERATION<-500

in_learning<-getDataSet(df$현재지수,1,102,INPUT_NODES)
in_learning

out_learning<-getDataSet(df$현재지수,11,107,OUTPUT_NODES)
out_learning

model<-nnet(in_learning,out_learning,size=HIDDEN_NODES,linout = TRUE,rang = 0.1,skip=TRUE,maxit = ITERATION)
#sizt=은닉층 노드 수
#linout=FALSE 모델 학습 시 모델의 출력과 원하는 값을 비교할 때 사용할 함수. TRUE면 엔트로피,FALSE면 SSE가 사용된다.
#skip:입력변수가 출력변수로 은닉층 없이 연결되는지 여부, 직접 연결시 T
#rang : 가중치의 초기값이 없다면 임의로 초기값 정함, (n, -rang, rang)
#maxit : 훈련 최적화를 위한 반복횟수

in_forecasting<-getDataSet(df$현재지수,98,107,INPUT_NODES)
in_forecasting

predicted_values<-predict(model,in_forecasting,type="raw")
predicted_values

real<-getDataSet(df$현재지수,108,112,OUTPUT_NODES)
real

ERR<-abs(real-predicted_values)
ERR

in_forecasting<-getDataSet(df$현재지수,177,186,INPUT_NODES)
in_forecasting

predicted_values<-predict(model,in_forecasting,type="raw")
predicted_values

plot(df$일자,df$현재지수)
lines(df$일자[187:191],predicted_values,type="o",col="red")
