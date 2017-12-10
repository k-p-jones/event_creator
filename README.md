### Event Creator

This project was born out of my reluctance to constantly be checking my emails and updating my google calendar to organise my weekend work.

Every week I receive many automated emails from my function
band agency telling me to 'hold the date' in my diary for a gig.
I also get emails confirming gigs and canceling gigs.

This little program reads my emails for me, extracts the required data and creates/updates/deletes events from my google calendar accordingly so I dont have to.

It's based on the bold assumption that the software my agency use to spam me with emails won't change its format for a while but I can live with that risk.

It is designed to run as a cron job on my pi and check my emails every hour and update my calendar for me.

cron command -> `cd /home/pi/event_creator ; ruby event_creator.rb 1 hours >> logs/event_creator.log 2>&1`