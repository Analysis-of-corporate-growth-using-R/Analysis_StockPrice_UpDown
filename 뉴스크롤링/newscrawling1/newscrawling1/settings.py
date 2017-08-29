# -*- coding: utf-8 -*-

# Scrapy settings for newscrawling1 project
#
# For simplicity, this file contains only settings considered important or
# commonly used. You can find more settings consulting the documentation:
#
#     http://doc.scrapy.org/en/latest/topics/settings.html
#     http://scrapy.readthedocs.org/en/latest/topics/downloader-middleware.html
#     http://scrapy.readthedocs.org/en/latest/topics/spider-middleware.html

BOT_NAME = 'newscrawling1'

SPIDER_MODULES = ['newscrawling1.spiders']
NEWSPIDER_MODULE = 'newscrawling1.spiders'

LOG_LEVEL='ERROR'

#Url
#ITEM_PIPELINES = {'newscrawling1.pipelines.CsvPipeline1':300, }

#Trans
#ITEM_PIPELINES = {'newscrawling1.pipelines.CsvPipeline2':300, }

#Article
ITEM_PIPELINES = {'newscrawling1.pipelines.CsvPipeline3':300, }
