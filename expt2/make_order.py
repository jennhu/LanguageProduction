
import os
import sys
import string
import random
import csv
from optparse import OptionParser
#from statlib import stats




#####################

class Order:
    
    def __init__(self):
        #assign parsed options
        self.options = self.parse()
        self.subjID = self.options.subjID
        self.list = self.options.list


        #file setup
        self.data_file = self.make_file()
        self.wr = csv.writer(self.data_file, quoting = csv.QUOTE_MINIMAL)
        self.wr.writerow(['List12','List34','ItemNum','Cond','Subcond','Item','Run'])


        [self.NO_H,self.NO_A,self.NO_O,self.RO_H,self.RO_A,self.RO_O,
         self.NE_H,self.NE_A,self.NE_O,self.RE_H,self.RE_A,self.RE_O]=self.open_file()
        self.runmake(1)
        self.runmake(2)
        self.runmake(3)
        self.runmake(4)
        
        self.write(self.NO_H)
        self.write(self.NO_A)
        self.write(self.NO_O)
        self.write(self.RO_H)
        self.write(self.RO_A)
        self.write(self.RO_O)
        self.write(self.NE_H)
        self.write(self.NE_A)
        self.write(self.NE_O)
        self.write(self.RE_H)
        self.write(self.RE_A)
        self.write(self.RE_O)
  
    def write(self,l):
        for item in l:
            self.wr.writerow(item)
            

    def open_file(self):
        f = open('Materials_FIN.csv', 'rU')
        read = csv.reader(f)
        all = [row for row in read if row[0]==self.list or row[1]==self.list]
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
    
        return [NO_H,NO_A,NO_O,RO_H,RO_A,RO_O,NE_H,NE_A,NE_O,RE_H,RE_A,RE_O]


    def runmake(self,n):
        for i in range((n-1)*4,4*n):
            self.NE_H[i].append(n)
            self.NE_A[i].append(n)
            self.NE_O[i].append(n)
            self.RE_H[i].append(n)
            self.RE_A[i].append(n)
            self.RE_O[i].append(n)
        for j in range((n-1)*12,12*n):
            self.NO_H[j].append(n)
            self.NO_A[j].append(n)
            self.NO_O[j].append(n)
            self.RO_H[j].append(n)
            self.RO_A[j].append(n)
            self.RO_O[j].append(n)
    def make_file(self):
        f = 'data/'+self.subjID+'_list'+str(self.list)+'_order'
        x = 1
        while os.path.isfile(f+'.csv'):
            x+=1
            f = 'data/'+self.subjID+'_list'+str(self.list)+'_x'+str(x)+'_order'
        data = open(f+'.csv','wb')
        return data

    def parse(self): #take command line options
        parser = OptionParser()
        parser.add_option("-s", "--subjID", dest="subjID")
        parser.add_option("-l", "--list", dest="list")
        (options,arg)=parser.parse_args()
        error = "ERROR:\n-s    give SubjID (any)\n-l    choose list: 1-4"
        if options.subjID == None:
            print error            
            sys.exit()
        if options.list not in ['1','2','3','4']:
            print error
            sys.exit()
        return options

    '''
    def add_category(self,line):
            if line in self.LaiS+self.LaanS+self.LaarS: line.append('LS')
            elif line in self.LaiD+self.LaanD+self.LaarD: line.append('LD')
            elif line in self.LaiC+self.LaanC+self.LaarC: line.append('LC')
            elif line in self.SaiS+self.SaanS+self.SaarS: line.append('SS')
            elif line in self.SaiD+self.SaanD+self.SaarD: line.append('SD')
            elif line in self.SaiC+self.SaanC+self.SaarC: line.append('SC')
            elif line in self.GaarS: line.append('GS')
            elif line in self.GaarD: line.append('GD')
            elif line in self.GaarC: line.append('GC')
            else: 
                print "PROBLEm"
            return line
            



    def make_run(self,run):

        ev_types = [[2,3,3],[3,2,3],[3,3,2]]
        l = [[self.LaiS,self.LaanS,self.LaarS],
             [self.LaiD,self.LaanD,self.LaarD],
             [self.LaiC,self.LaanC,self.LaarC]]
        s = [[self.SaiS,self.SaanS,self.SaarS],
             [self.SaiD,self.SaanD,self.SaarD],
             [self.SaiC,self.SaanC,self.SaarC]]
        g = [self.GaarS,self.GaarD,self.GaarC]

        
        
        random.shuffle(l)
        random.shuffle(s)
    
        if run!=6:
            for m in range(3):
                for n in range(3):
                    for p in range(ev_types[m][n]):
                        self.wr.writerow([self.subjID,run]+self.add_category(l[m][n][-1]))               
                        l[m][n].pop()
                    for q in range(ev_types[m][n]):
                        self.wr.writerow([self.subjID,run]+self.add_category(s[m][n][-1]))
                        s[m][n].pop()
                for r in range(8):
                    self.wr.writerow([self.subjID,run]+self.add_category(g[m][-1]))
                    g[m].pop()
        elif run==6:
            for t in (self.LaiS+self.LaanS+self.LaarS+self.LaiD+self.LaanD+self.LaarD+self.LaiC+self.LaanC+self.LaarC+self.SaiS+self.SaanS+self.SaarS+self.SaiD+self.SaanD+self.SaarD+self.SaiC+self.SaanC+self.SaarC+self.GaarS+self.GaarD+self.GaarC):
                self.wr.writerow([self.subjID,run]+self.add_category(t))
            return 'finished'

        '''


def Main():
    o = Order()
   

    

Main()
  
            
