#!/usr/bin/env python
# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = 'Chris Jones'
SITENAME = 'cmsj.net'
SITEURL = 'http://cmsj.net'

PATH = 'content'
STATIC_PATHS = ['images']
DISPLAY_ARTICLE_INFO_ON_INDEX = True
HIDE_SIDEBAR = True

THEME = 'themes/hss'
DEFAULT_PAGINATION = 10

TIMEZONE = 'Europe/London'
DEFAULT_LANG = 'en'

JINJA_ENVIRONMENT = {'extensions': ['jinja2.ext.i18n']}
PLUGIN_PATHS = ['plugins']
PLUGINS = ['i18n_subsites']

# Feed generation is usually not desired when developing
FEED_DOMAIN = SITEURL
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None
TRANSLATION_FEED = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None
FEED_ATOM = ('atom.xml')
FEED_RSS = ('feed.xml')
RSS_FEED_SUMMARY_ONLY = False

# Social widget
SOCIAL = (('twitter', 'https://twitter.com/cmsj'),
          ('github', 'https://github.com/cmsj'))

ARTICLE_URL = '{date:%Y}/{date:%m}/{date:%d}/{slug}.html'
ARTICLE_SAVE_AS = '{date:%Y}/{date:%m}/{date:%d}/{slug}.html'
ARCHIVES_URL = 'archive.html'
