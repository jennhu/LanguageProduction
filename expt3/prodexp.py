
import os
import sys
import string
import Image
import random
import csv
import pygame
from pygame.locals import *
from optparse import OptionParser
#from statlib import stats
from VisionEgg import *
start_default_logging(); watch_exceptions()
from VisionEgg.Core import *
from VisionEgg.FlowControl import *
from VisionEgg.Textures import *
from VisionEgg.MoreStimuli import *
from VisionEgg.Text import *

#Zuzanna Balewski


#####################

class Experiment:
    
    def __init__(self):
        
        #assign parsed options
        self.options = self.parse()
        self.subjID = self.options.subjID
        self.list = self.options.list
        self.run = self.options.run
        self.order = self.options.orders
        

        #experiment constants
        self.init_fix_time = 18.000
        self.small_fix_time = 0.250
        self.display=3.750
        self.instructions =2.000
        
        self.black = (0.0,0.0,0.0)
        self.blue = (0.0,0.0,1.0)
        self.white = (1.0,1.0,1.0)
        self.font_size = 55


        #screen/VisionEgg setup
        self.screen = Screen(bgcolor=self.white, size = (1280, 1024), fullscreen=True) ##uncomment to make fullscreen
        self.center = (self.screen.size[0]/2.0, self.screen.size[1]/2.0)

        self.start = self.black_text('Wait for trigger +')
        self.fix = FixationCross(position=self.center, size=(75.0,75.0))

        self.view_start = Viewport(screen=self.screen, stimuli=[self.start])
        self.view_presentation = Viewport(screen=self.screen)

        self.p = Presentation()


        [self.NO_H,self.NO_A,self.NO_O,self.RO_H,self.RO_A,self.RO_O,
         self.NE_H,self.NE_A,self.NE_O,self.RE_H,self.RE_A,self.RE_O]=self.open_file()
       


        self.i = 0
        self.j = 0
        self.last_start = 0
        self.ideal = 0
        self.trial_n = 0
        self.RT = None
        self.given_response = None
        self.correct = None
        self.choice_onset = None
        self.acc = None

        # Not using optseq files
        self.order = self.organize_items()
        print self.order

        

        #data file setup
        self.data_file = self.make_file()
        self.wr = csv.writer(self.data_file, quoting=csv.QUOTE_MINIMAL)
        self.wr.writerow(['SubjID','Time','Run','Trial','List','Cond','Subcond','Order','Item 1','Item 2','Item 3','Item 1 #','Item 2 #','Item 3 #'])

    def open_file(self):
        f = open('data/'+self.subjID+'_list'+self.list+'_order.csv', 'rU')
        read = csv.reader(f)
        all = [row for row in read if row[6]==self.run]
        for i in all:
            i.append(i[5])
        random.shuffle(all)
        NO_H=[i for i in all if i[3]=='NO' and i[4]=='H']
        NO_A=[i for i in all if i[3]=='NO' and i[4]=='A']
        NO_O=[i for i in all if i[3]=='NO' and i[4]=='O']
        RO_H=[i for i in all if i[3]=='RO' and i[4]=='H']
        RO_A=[i for i in all if i[3]=='RO' and i[4]=='A']
        RO_O=[i for i in all if i[3]=='RO' and i[4]=='O']
        NE_H=[i for i in all if i[3]=='NE' and i[4]=='H']
        NE_A=[i for i in all if i[3]=='NE' and i[4]=='A']
        NE_O=[i for i in all if i[3]=='NE' and i[4]=='O']
        RE_H=[i for i in all if i[3]=='RE' and i[4]=='H']
        RE_A=[i for i in all if i[3]=='RE' and i[4]=='A']
        RE_O=[i for i in all if i[3]=='RE' and i[4]=='O']
        
        
        k=1
        for j in NO_H:
            pic=Texture(os.path.join('image_files/Human', j[5]))
            print 'H',j[5]
            if k==1:
                j[5]=TextureStimulus(texture = pic,
                                      anchor = 'center',
                                      position = (self.screen.size[0]/4,self.screen.size[1]*3/4))
                k+=1
            elif k==2:
                j[5]=TextureStimulus(texture = pic,
                                      anchor = 'center',
                                      position = (self.screen.size[0]*3/4,self.screen.size[1]*3/4))
                k+=1
            elif k==3:
                j[5]=TextureStimulus(texture = pic,
                                      anchor = 'center',
                                      position = (self.screen.size[0]/2,self.screen.size[1]/4))
                k=1
        
        for j in NO_A:
            print 'A',j[5]
            pic=Texture(os.path.join('image_files/Animals',j[5]))
            if k==1:
                j[5]=TextureStimulus(texture = pic,
                                      anchor = 'center',
                                      position = (self.screen.size[0]/4,self.screen.size[1]*3/4))
                k+=1
            elif k==2:
                j[5]=TextureStimulus(texture = pic,
                                      anchor = 'center',
                                      position = (self.screen.size[0]*3/4,self.screen.size[1]*3/4))
                k+=1
            elif k==3:
                j[5]=TextureStimulus(texture = pic,
                                      anchor = 'center',
                                      position = (self.screen.size[0]/2,self.screen.size[1]/4))
                k=1
        
        for j in NO_O:
            print j[5]
            pic=Texture(os.path.join('image_files/Object', j[5]))
            if k==1:
                j[5]=TextureStimulus(texture = pic,
                                      anchor = 'center',
                                      position = (self.screen.size[0]/4,self.screen.size[1]*3/4))
                k+=1
            elif k==2:
                j[5]=TextureStimulus(texture = pic,
                                      anchor = 'center',
                                      position = (self.screen.size[0]*3/4,self.screen.size[1]*3/4))
                k+=1
            elif k==3:
                j[5]=TextureStimulus(texture = pic,
                                      anchor = 'center',
                                      position = (self.screen.size[0]/2,self.screen.size[1]/4))
                k=1
        

        for j in NE_H:
            print j[5]
            pic=Texture(os.path.join('image_files/Human-Human', j[5]))
            j[5]=TextureStimulus(texture = pic,
                                      anchor = 'center',
                                      position = self.center)
        for j in NE_A:
            print j[5]
            pic=Texture(os.path.join('image_files/Human-Animal', j[5]))
            j[5]=TextureStimulus(texture = pic,
                                      anchor = 'center',
                                      position = self.center)
        for j in NE_O:
            print j[5]
            pic=Texture(os.path.join('image_files/Human-Object', j[5]))
            j[5]=TextureStimulus(texture = pic,
                                      anchor = 'center',
                                      position = self.center)     


        


        for j in RO_H:
            
            print 'H',j[5]
            if k==1:
                j[5]=Text(anchor= 'center',
                            position = (self.screen.size[0]/3,self.screen.size[1]*2/3),
                            font_size=self.font_size,
                            color=self.black,
                            text=j[5])
                k+=1
            elif k==2:
                j[5]=Text(anchor= 'center',
                            position = (self.screen.size[0]*2/3,self.screen.size[1]*2/3),
                            font_size=self.font_size,
                            color=self.black,
                            text=j[5])
                
                k+=1
            elif k==3:
                j[5]=Text(anchor= 'center',
                            position = (self.screen.size[0]/2,self.screen.size[1]/3),
                            font_size=self.font_size,
                            color=self.black,
                            text=j[5])
                k=1

        for j in RO_A:
            
            print 'A',j[5]
            if k==1:
                j[5]=Text(anchor= 'center',
                            position = (self.screen.size[0]/3,self.screen.size[1]*2/3),
                            font_size=self.font_size,
                            color=self.black,
                            text=j[5])
                k+=1
            elif k==2:
                j[5]=Text(anchor= 'center',
                            position = (self.screen.size[0]*2/3,self.screen.size[1]*2/3),
                            font_size=self.font_size,
                            color=self.black,
                            text=j[5])
                
                k+=1
            elif k==3:
                j[5]=Text(anchor= 'center',
                            position = (self.screen.size[0]/2,self.screen.size[1]/3),
                            font_size=self.font_size,
                            color=self.black,
                            text=j[5])
                k=1
                
        for j in RO_O:
            
            print 'O',j[5]
            if k==1:
                j[5]=Text(anchor= 'center',
                            position = (self.screen.size[0]/3,self.screen.size[1]*2/3),
                            font_size=self.font_size,
                            color=self.black,
                            text=j[5])
                k+=1
            elif k==2:
                j[5]=Text(anchor= 'center',
                            position = (self.screen.size[0]*2/3,self.screen.size[1]*2/3),
                            font_size=self.font_size,
                            color=self.black,
                            text=j[5])
                
                k+=1
            elif k==3:
                j[5]=Text(anchor= 'center',
                            position = (self.screen.size[0]/2,self.screen.size[1]/3),
                            font_size=self.font_size,
                            color=self.black,
                            text=j[5])
                k=1
                
        for j in RE_H:
            print j[5]
            j[5]=Text(anchor='center',
                            position = self.center,
                            font_size=self.font_size,
                            color=self.black,
                            text=j[5])
        for j in RE_A:
            print j[5]
            j[5]=Text(anchor='center',
                            position = self.center,
                            font_size=self.font_size,
                            color=self.black,
                            text=j[5])
        for j in RE_O:
            print j[5]
            j[5]=Text(anchor='center',
                            position = self.center,
                            font_size=self.font_size,
                            color=self.black,
                            text=j[5])
    

    

    
        return [NO_H,NO_A,NO_O,RO_H,RO_A,RO_O,NE_H,NE_A,NE_O,RE_H,RE_A,RE_O]


        
    def parse(self):
        parser = OptionParser()
        parser.add_option("-s", "--subjID", dest="subjID")
        parser.add_option("-l", "--list", dest="list")
        parser.add_option("-r", "--run", dest="run")
        parser.add_option("-o", "--orders", dest="orders")
        (options,arg)=parser.parse_args()
        error = "ERROR\n-s    give subjID (same as order file)\n-l    choose list (same as order file)\n-r    choose run: 1-6\n-o    choose order: any\n"
        choices = [str(i) for i in range(1,7)]
        if options.subjID==None:
            print error
            sys.exit()
        if options.list not in ['1','2','3','4']:
            print error
            sys.exit()
        if options.run not in ['1','2','3','4']:
            print error
            sys.exit()
        if options.orders not in ['1','2','3','4']:
            print error
            sys.exit() 
        return options


    
    def make_file(self):
        f = 'data/'+self.subjID+'_list'+str(self.list)+'_run'+self.run+'_data'
        x=1
        while os.path.isfile(f+'.csv'):
            x+=1
            f = 'data/'+self.subjID+'_run'+self.run+'-x'+str(x)+'_data'
        return open(f+'.csv','wb')

    def organize_items(self):
        if self.order=='1':
            o=['Fix','NameObj','NO','NO','NO','NO','NameEv','NE','NE','NE','NE','ReadObj','RO','RO','RO','RO','ReadEv','RE','RE','RE','RE','Fix','ReadObj','RO','RO','RO','RO','NameObj','NO','NO','NO','NO','NameEv','NE','NE','NE','NE','ReadEv','RE','RE','RE','RE','Fix','ReadEv','RE','RE','RE','RE','ReadObj','RO','RO','RO','RO','NameEv','NE','NE','NE','NE','NameObj','NO','NO','NO','NO','Fix']
        elif self.order=='2':
            o=['Fix','NameEv','NE','NE','NE','NE','ReadObj','RO','RO','RO','RO','ReadEv','RE','RE','RE','RE','NameObj','NO','NO','NO','NO','Fix','ReadEv','RE','RE','RE','RE','NameEv','NE','NE','NE','NE','ReadObj','RO','RO','RO','RO','NameObj','NO','NO','NO','NO','Fix','NameObj','NO','NO','NO','NO','ReadEv','RE','RE','RE','RE','ReadObj','RO','RO','RO','RO','NameEv','NE','NE','NE','NE','Fix']
        elif self.order=='3':
            o=['Fix','ReadObj','RO','RO','RO','RO','ReadEv','RE','RE','RE','RE','NameObj','NO','NO','NO','NO','NameEv','NE','NE','NE','NE','Fix','NameObj','NO','NO','NO','NO','ReadObj','RO','RO','RO','RO','ReadEv','RE','RE','RE','RE','NameEv','NE','NE','NE','NE','Fix','NameEv','NE','NE','NE','NE','NameObj','NO','NO','NO','NO','ReadEv','RE','RE','RE','RE','ReadObj','RO','RO','RO','RO','Fix']
        elif self.order=='4':
            o=['Fix','ReadEv','RE','RE','RE','RE','NameObj','NO','NO','NO','NO','NameEv','NE','NE','NE','NE','ReadObj','RO','RO','RO','RO','Fix','NameEv','NE','NE','NE','NE','ReadEv','RE','RE','RE','RE','NameObj','NO','NO','NO','NO','ReadObj','RO','RO','RO','RO','Fix','ReadObj','RO','RO','RO','RO','NameEv','NE','NE','NE','NE','NameObj','NO','NO','NO','NO','ReadEv','RE','RE','RE','RE','Fix']
        x=[['H']*4, ['A']*4, ['O']*4]
        print x

        # Shuffles it so we get 4 in a row of each type (H,A,O)
        temp_ord = []
        random.shuffle(x)
        for i in x:
            for j in i:
                temp_ord += j
        NO_ord=temp_ord

        temp_ord = []
        random.shuffle(x)
        for i in x:
            for j in i:
                temp_ord += j
        NE_ord=temp_ord
        
        temp_ord = []
        random.shuffle(x)
        for i in x:
            for j in i:
                temp_ord += j
        RE_ord=temp_ord

        temp_ord = []
        random.shuffle(x)
        for i in x:
            for j in i:
                temp_ord += j
        RO_ord=temp_ord
        

        
        self.items = []

        i=0
        j=0
        k=0
        l=0
        for y in o:
            if y=='Fix':
                self.items.append('Fix')

            elif y=='NameObj':
                self.items.append('NameObj')

            elif y=='NameEv':
                self.items.append('NameEv')
                
            elif y=='ReadObj':
                self.items.append('ReadObj')

            elif y=='ReadEv':
                self.items.append('ReadEv')
                
            elif y=='NO':
                print NO_ord[i]
                if NO_ord[i]=='H':
                    self.items=self.items+[[self.NO_H.pop(),self.NO_H.pop(),self.NO_H.pop()]]
                if NO_ord[i]=='A':
                    self.items=self.items+[[self.NO_A.pop(),self.NO_A.pop(),self.NO_A.pop()]]
                if NO_ord[i]=='O':
                    self.items=self.items+[[self.NO_O.pop(),self.NO_O.pop(),self.NO_O.pop()]]
                i=i+1
            elif y=='RO':
                if RO_ord[j]=='H':
                    self.items=self.items+[[self.RO_H.pop(),self.RO_H.pop(),self.RO_H.pop()]]
                if RO_ord[j]=='A':
                    self.items=self.items+[[self.RO_A.pop(),self.RO_A.pop(),self.RO_A.pop()]]
                if RO_ord[j]=='O':
                    self.items=self.items+[[self.RO_O.pop(),self.RO_O.pop(),self.RO_O.pop()]]
                j=j+1
            elif y=='NE':
                if NE_ord[k]=='H':
                    self.items=self.items+[[self.NE_H.pop()]]
                if NE_ord[k]=='A':
                    self.items=self.items+[[self.NE_A.pop()]]
                if NE_ord[k]=='O':
                    self.items=self.items+[[self.NE_O.pop()]]
                k+=1
            elif y=='RE':
                if RE_ord[l]=='H':
                    self.items=self.items+[[self.RE_H.pop()]]
                if RE_ord[l]=='A':
                    self.items=self.items+[[self.RE_A.pop()]]
                if RE_ord[l]=='O':
                    self.items=self.items+[[self.RE_O.pop()]]
                l+=1
                
    
        return self.items
    
                       

    def black_text(self,txt):
        return Text(anchor = 'center',
                    position = self.center,
                    font_size = self.font_size,
                    color = self.black,
                    text = txt)
    def blue_text(self,txt):
        return Text(anchor = 'center',
                    position = self.center,
                    font_size = self.font_size,
                    color = self.blue,
                    text = string.upper(txt))

    ### NOT USING CORRECT/ INCORRECT PROBE###
    #def choose_probe(self,current):
     #   p = random.choice(['correct','incorrect'])
      #  if p == 'correct':
       #     self.probe = random.choice(current[13:19])
        #    self.correct = 1
       # else:
        #    self.probe = random.choice(current[19:25])
         #   self.correct = 0
        #return self.probe

        





    ###### PRESENATION ######

    def finish(self, event): #quit anytime
        if event.key == pygame.locals.K_ESCAPE:
            self.screen.close()
            sys.exit()       

    def trigger(self, event): #start exp
        if event.unicode == '+': self.p.parameters.go_duration = (0, 'seconds')

    def trigger_screen_go(self): #trigger screen presentation
        self.p.parameters.handle_event_callbacks = [(pygame.locals.KEYDOWN, self.trigger),
                                                    (pygame.locals.KEYDOWN, self.finish)]
        self.p.parameters.go_duration = ('forever',)
        self.p.parameters.viewports = [self.view_start]
        self.p.go()

    def response(self, event): #take, record responses (1=correct probe, 2=incorrect prob)
        if event.key == pygame.locals.K_KP1 or event.key == pygame.locals.K_1: 
            self.RT = self.p.time_sec_since_go-self.choice_onset
            self.given_response = 1
            self.p.parameters.handle_event_callbacks = [(pygame.locals.KEYDOWN, self.finish)]
        if event.key == pygame.locals.K_KP2 or event.key == pygame.locals.K_2:
            self.RT = self.p.time_sec_since_go- self.choice_onset
            self.given_response = 0
            self.p.parameters.handle_event_callbacks = [(pygame.locals.KEYDOWN, self.finish)] 
        if self.given_response == self.correct: self.acc = 1
        else: self.acc = 0






            
    def switch(self,t): #display trials
        if self.i<len(self.order):
            current = self.order[self.i]
            print 'current ',current
            
            if self.i < len(self.order)-2:
                print 'next ',self.order[self.i+1]
                print 'next*2 ',self.order[self.i+2]
                
            elif self.i == len(self.order)-2:
                print 'next ',self.order[self.i+1]
                print "Second to Last"

            elif self.i == len(self.order)-1:
                print 'last'
        
            
           
            if current=='Fix':
                if t<=(self.ideal+self.init_fix_time):
                    return [self.fix]
                else:
                    self.i += 1
                    self.last_start = t
                    self.ideal+=self.init_fix_time
                    return [self.fix]


            elif current == 'NameObj':
                if t<=self.ideal+self.instructions:
                    return [self.black_text('NAME THE OBJECTS')]

                else:
                     self.i+=1
                     self.ideal += self.instructions        
                     self.j=0
                     self.last_start = t
                     self.acc = None
                     self.given_response = None
                     self.RT = None
                     self.correct = None
                     self.choice_onset = None
                     
                     return []
                    
            elif current == 'NameEv':
                if t<=self.ideal+self.instructions:
                    return [self.black_text('DESCRIBE THE EVENT')]

                else:
                     self.i+=1
                     self.ideal += self.instructions        
                     self.j=0
                     self.last_start = t
                     self.acc = None
                     self.given_response = None
                     self.RT = None
                     self.correct = None
                     self.choice_onset = None
                     
                     return []

            elif current == 'ReadObj':
                if t<=self.ideal+self.instructions:
                    return [self.black_text('READ THE WORDS')]

                else:
                     self.i+=1
                     self.ideal += self.instructions        
                     self.j=0
                     self.last_start = t
                     self.acc = None
                     self.given_response = None
                     self.RT = None
                     self.correct = None
                     self.choice_onset = None
                     
                     return []
                    
            elif current == 'ReadEv':
                if t<=self.ideal+self.instructions:
                    return [self.black_text('READ THE SENTENCE')]

                else:
                     self.i+=1
                     self.ideal += self.instructions        
                     self.j=0
                     self.last_start = t
                     self.acc = None
                     self.given_response = None
                     self.RT = None
                     self.correct = None
                     self.choice_onset = None
                     
                     return []
        
            else:
                if t<=(self.ideal+self.small_fix_time):
                    return [self.fix]

                elif t<=self.ideal+self.small_fix_time+self.display:        
                    if len(current)==1:
                        return [current[0][5]]
                    else:
                        return [current[0][5],current[1][5],current[2][5]]
                                            
                else:
                     self.i+=1
                     self.ideal+=self.small_fix_time+self.display          
                     if len(current)==3:
                         self.trial_n+=1
                         self.wr.writerow([self.subjID,self.last_start,self.run,self.trial_n,self.list]+[current[0][3]]+[current[0][4]]+[current[0][6]]+[current[0][7],current[1][7],current[2][7]]+[current[0][2],current[1][2],current[2][2]])#current[7],current[4],'times-00'+self.opt,self.trial_n,current[6],current[5],current[8],current[9],current[10],current[11],current[12],self.probe,self.correct,self.given_response,self.acc,self.RT,self.choice_onset])
                     elif len(current)==1:
                         self.trial_n+=1
                         self.wr.writerow([self.subjID,self.last_start,self.run,self.trial_n,self.list]+[current[0][3]]+[current[0][4]]+[current[0][6]]+[current[0][7]]+[[]]+[[]]+[current[0][2]]+[[]]+[[]])
                     self.j=0
                     self.last_start = t
                     self.acc = None
                     self.given_response = None
                     self.RT = None
                     self.correct = None
                     self.choice_onset = None
                     
                     
                     return [self.fix]
        else:
            #end presentation
            self.p.parameters.go_duration=(0,'seconds')
            return []

    def run_go(self):
        self.p.parameters.handle_event_callbacks = [(pygame.locals.KEYDOWN, self.finish)]
        self.p.parameters.go_duration = ('forever',)
        
        self.p.parameters.viewports = [self.view_presentation]
        self.p.add_controller(self.view_presentation, 'stimuli', FunctionController(during_go_func=self.switch))
        self.p.go()
    
        






def Main():
    new_run = Experiment()
    new_run.trigger_screen_go()
    new_run.run_go()


Main()
