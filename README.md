Ripeline
========

Build pipelines with Ruby.


A story I shall tell you
========================

I was building a Github crawler to download a bunch of code, and after I hacked something together I basically had built an ad-hoc pipeline. The crawler was split up into stages (roughly: find user, parse github user page, find repos, download code), and each stage was a producer, a consumer, or a producer and a consumer, and I was using redis queues to communicate between stages. It looked like this:

    find users <----<redis queue>----> parse user page and find repos <----<redis queue>----> download code --------> mongo collection

My hacked up version worked... until it didn't and started sucking to maintain. I was repeating code everywhere to get stuff out of a queue, do some stuff, put the result in a queue, and loop forever. Also, testing all this code meant firing up a redis instance and then firing up each stage in a separate process, and looking at each process to determine where errors came (and oh, did they ever come!) Often, when I found a backtrace, the pipeline stage was already dead and repro-ing it would take another whole run. Do not pass go, do not collect $200.

A better way was needed, so I looked around for a good way to build pipelines in ruby. I Googled "build a pipeline with ruby," and the first result I got was [http://www.pipelineandgasjournal.com/gip-and-el-paso-partner-build-ruby-pipeline](http://www.pipelineandgasjournal.com/gip-and-el-paso-partner-build-ruby-pipeline). Not a good sign. So I started building Ripeline. I'm basing it loosely on the ideas in appengine-pipeline ([http://code.google.com/p/appengine-pipeline/](http://code.google.com/p/appengine-pipeline/)), except I designed the stages to run forever, so I didn't build in any futures or promises.

My first goal is to DRY things up. Right now, Ripeline does all the exception catching and reporting for you, and manages all the incoming and outgoing queues. I'm gonna build a good way to test each stage deterministically, and then I'm gonna add a process manager & scheduler so that you can run these bad boys in a production environment.

I want to be able to eventually run 'rake ripeline:start' and have that command start up all the pipeline stages on different machines, and also have a simple web based UI that lets you see the status of each pipeline stage (stages already do basic reporting) and each queue.

As I write this, Ripeline is less than 2 days old, so it's not in a gem yet, and it's super unstable. So don't install it. But if you must, just git clone git@github.com:arschles/ripeline.git and go to town.

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