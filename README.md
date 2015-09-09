# ff-rankiger (Followee's Followee Rankinger)

## Abstract

This Ruby script output *Followee's Followee Ranking List* (to HTML file). To use this script, you have to prepare a Twitter Application (You can create Twitter Application at [Twitter Developers](https://dev.twitter.com/)). You also need more than one Twitter account (of course). One of them will be investigation object (Target), and the others will be research acounts. With this script, you can use any number of research acounts.

## Usage

1. Write your application's Consumer Key and Consumer Secret in the script.
2. Write target's Access Token and Access Token Secret in the script.
3. Write research acounts' Access Token and Access Token Secret in the script, if you need.
4. Run `ruby hb-converter.rb` .

## Options

You can change the value of following costants.

* int `MAX_RANK` : control the length of output list.
* bool `EXCEPT_MY_FOLLOWEE` : except target's followee from the list (true) or not (false).