# -*- coding: utf-8 -*-

import scrapy
import time
import csv
from newscrawling1.items import Newscrawling1Item
from urllib2 import urlopen
from bs4 import BeautifulSoup

class NewsUrlSpider(scrapy.Spider):
    name = "newsUrlCrawler1"
    
    def start_requests(self):
        pageNum = 60
        startdate = 20150812
        enddate = 20170811
        for i in range(1, pageNum, 1):
            yield scrapy.Request("http://search.daum.net/search?w=news&sort=recency&q=gs%ED%99%88%EC%87%BC%ED%95%91&cluster=n&s=NS&a=STCF&dc=STC&pg=1&r=1&p={0}&rc=1&at=more&cpname=%ED%95%9C%EA%B5%AD%EA%B2%BD%EC%A0%9C&cp=16qCuwnoTf8fLmrhD1&DA=PGD&sd={1}000000&ed={2}235959&period=u".format(i,startdate,enddate),self.parse_news)

    def parse_news(self, response):
        for sel in response.xpath('//*[@id="mArticle"]/div/div[2]/div/div[3]/ul/li'):
            item = Newscrawling1Item()
            
            item['url'] = sel.xpath('div[@class="wrap_cont"]/div/div/a/@href').extract()[0]
            
            print('*'*100)
            print(item['url'])
            
            #time.sleep(5)
            
            yield item

class NewsTransSpider(scrapy.Spider):
    name = "newsTransCrawler1"
    
    
    def start_requests(self):
        with open('newsUrlCrawl1.csv') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                yield scrapy.Request(row['url'],self.parse_news)

    def parse_news(self, response):
        item = Newscrawling1Item()
        response = str(response)[5:-1]
        item['url'] = response
        print(response)
    
        yield item

class NewsSpider(scrapy.Spider):
    name = "newsCrawler1"

    def start_requests(self):
        with open('newsTransCrawl1.csv') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                yield scrapy.Request(row['url'],self.parse_news)
    
    def parse_news(self, response):
        item = Newscrawling1Item()
        item['url'] = response
        
        if str(response)[12:15]=='hei':
            
            item['title'] = response.xpath('//*[@id="container"]/section/h1/text()').extract()[0]
            item['date'] = response.xpath('//*[@id="container"]/section/div/div/span/text()').extract()[0][5:13]

            html=urlopen(str(response)[5:-1])
            soup=BeautifulSoup(html,'html.parser')
            s=str(soup.article)
            while True:
                a=s.find('<')
                if a==-1:
                    break
                b=s.find('>')+1
                s=s[:a]+s[b:]
            item['article'] = s
                
            print('*'*100)
            print(item['title'])
            print(item['date'])
            print(item['article'])
        
        elif str(response)[12:15]=='new':
            
            item['title'] = response.xpath('//*[@id="container"]/div/h2/text()').extract()[0]
            item['date'] = response.xpath('//*[@id="container"]/div[2]/div/div/div/span/span/text()').extract()[0][2:10]
            item['article'] = response.xpath('//*[@id="newsView"]/text()').extract()
            

            print('*'*100)
            print(item['title'])
            print(item['date'])
            print(item['article'])

        elif str(response)[12:15]=='sto':
            
            item['title'] = response.xpath('//*[@id="contents"]/div/div[3]/h1/text()').extract()[0]
            item['date'] = response.xpath('//*[@id="contents"]/div/div[4]/span/text()').extract()[0][5:13]
            item['article'] = response.xpath('//*[@id="contents"]/div[2]/div[5]/text()').extract()
            
            print('*'*100)
            print(item['title'])
            print(item['date'])
            print(item['article'])

        elif str(response)[12:15]=='hea':
        
            item['title'] = response.xpath('//h4[@id="subject"]/text()').extract()[0]
            item['date'] = response.xpath('//stan[@id="pubdate"]/text()').extract()[0]
            item['article'] = response.xpath('//*[@id="newsView"]/text()').extract()
            
            print('*'*100)
            print(item['title'])
            print(item['date'])
            print(item['article'])
        
        
        elif str(response)[12:15]=='mar':

            item['title'] = response.xpath('//*[@id="container"]/div/div/div/h1/text()').extract()[0]
            item['date'] = response.xpath('//*[@id="container"]/div/div/div/div/em/span/text()').extract()[0][2:10]
            item['article'] = response.xpath('//*[@id="newsView"]/text()').extract()
            
            print('*'*100)
            print(item['title'])
            print(item['date'])
            print(item['article'])

        elif str(response)[12:15]=='sna':
    
            item['title'] = response.xpath('//article[@class="post-body"]/div/h1/text()').extract()[0]
            item['date'] = response.xpath('//article[@class="post-body"]/div[2]/p/span/text()').extract()[0][5:13]
            item['article'] = response.xpath('//div[@class="post-article"]/text()').extract()
            
            print('*'*100)
            print(item['title'])
            print(item['date'])
            print(item['article'])
        
        yield item
