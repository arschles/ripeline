Ripeline
========

Build pipelines with Ruby.


A story I shall tell you
========================

I was building a Github crawler to download a bunch of code, and after I hacked something together I basically had built an ad-hoc pipeline. The crawler was split up into stages (roughly: find user, parse user page, find repos, download code), and each stage was a producer, a consumer, or a producer and a consumer, and I was using redis queues to communicate between stages. It looked like this:

    find users ----redis queue ----> redis queue <----redis queue ----> parse user page and find repos <---- redis queue ----> download code --------> mongo collection

My hacked up version worked... until it didn't. I was repeating code everywhere to get stuff out of a queue, do some stuff, put the result in a queue, and then loop forever. It's only a little bit of code repeating, but it started adding up as I added more and more stages, and that was starting to suck. I also didn't have any error reporting or statistics, which I was really starting to miss when my code started throwing exceptions.

A better way was needed, so I looked around for a good way to build pipelines in ruby. I Googled "build a pipeline with ruby," and the first result I got was [http://www.pipelineandgasjournal.com/gip-and-el-paso-partner-build-ruby-pipeline](http://www.pipelineandgasjournal.com/gip-and-el-paso-partner-build-ruby-pipeline). Not a good sign. So I started building Ripeline. I'm basing it loosely on the ideas in appengine-pipeline ([http://code.google.com/p/appengine-pipeline/](http://code.google.com/p/appengine-pipeline/)), except I designed the stages to run forever, so I didn't build in any futures or promises.

Right now, Ripeline does all the exception catching and reporting for you, and manages all the incoming and outgoing queues. I'm gonna add a process manager & scheduler sometime soon too, because I want to be able to eventually run rake ripeline:start and have that start up all the pipeline stages on different machines, and also have a web UI for all the pipeline stages.

As I'm writing this, Ripeline is less than 2 days old, so it's not in a gem yet. To install it, just git clone git@github.com:arschles/ripeline.git

Example
=======

Creating a stage is similar to doing it in appengine-pipeline:
    
    require 'ripeline/stage'
    
    class MyStage < Ripeline::Stage
      def run elt
        #this gets called once per element that gets pulled out of the pull queue
        new_elt = do_some_stuff(elt)
        #the return val gets pushed onto the push queue. clever naming, I know
        new_elt
      end
    end

Then, starting the stage is also similar:

    stage = MyStage.new :pullq, :pushq
    stage.start

The stage will run forever, pulling elements from :pullq, calling stage.run for each element, and then pushing run's return values into :pushq. 
If run ever throws, the stage will skip that element and continue. I'm working on adding exception reporting to Mongo.