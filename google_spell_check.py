#!/usr/bin/python
# -*- coding: utf-8 -*-
import re, os,urllib2, sys
def correct(text):
	# grab html
	html = get_page('http://www.google.com/search?q=' + urllib2.quote(text))

	# save html for debugging
	# open('page.html', 'w').write(html)

	# pull pieces out
	match = re.search(r'(?:Showing results for|Did you mean|Including results for)[^\0]*?<a.*?>(.*?)</a>', html)
	if match is None:
		fix = text
	else:
		fix = match.group(1)
		fix = re.sub(r'<.*?>', '', fix);

	# return result
	return fix

def get_page(url):
	# the type of header affects the type of response google returns
	# for example, using the commented out header below google does not 
	# include "Including results for" results and gives back a different set of results
	# than using the updated user_agent yanked from chrome's headers
	# user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.7) Gecko/2009021910 Firefox/3.0.7'
	user_agent = 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.116 Safari/537.36'
	headers = {'User-Agent':user_agent,}
	req = urllib2.Request(url, None, headers)
	page = urllib2.urlopen(req)
	html = str(page.read())
	page.close()
	return html
        
if len(sys.argv) != 2:
    sys.exit('Usage: %s word' % sys.argv[0])

word = sys.argv[1]
sys.stdout.write(correct(word))