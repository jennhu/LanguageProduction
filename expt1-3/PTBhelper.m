% Helpful Subfunctions for Psychtoolbox experiments
%  Send inputs starting with the function name then that function's inputs
%  	ex. PTBhelper('waitFor',500,1,'ESCAPE')
%  Returns outputs in the form of a cell array of all outputs for a given function
%
function out = PTBhelper(func,varargin)
	out={};
	switch func
		case 'initialize'
			if length(varargin)<1, disp(['Error: not enough arguments for func ' func]);return;end
			[out{1},out{2},out{3},out{4}] = initialize(varargin{1});
		case 'waitFor'
			if length(varargin)<3, disp(['Error: not enough arguments for func ' func]);return;end
			[out{1}, out{2}] = waitFor(varargin{1},varargin{2},varargin{3});
		case 'getKeyboardIndex'
			[out{1},out{2}] = getKeyboardIndex();
		case 'stimImage'
			if length(varargin)<2, disp(['Error: not enough arguments for func ' func]);return;
			elseif length(varargin)==2
                stimImage(varargin{1},varargin{2});
			elseif length(varargin)==3
                stimImage(varargin{1},varargin{2},varargin{3});
			end
		case 'stimText'
			if length(varargin)<1, disp(['Error: not enough arguments for func ' func]);return;
			elseif length(varargin)==2
				stimText(varargin{1},varargin{2});
			elseif length(varargin)==3
				stimText(varargin{1},varargin{2},varargin{3});
			%elseif length(varargin)==5
			%	stimText(varargin{1},varargin{2},varargin{3},varargin{4},varargin{5});
			end
		case 'stimSound'
			if length(varargin)<2, disp(['Error: not enough arguments for func ' func]);return;end
			stimSound(varargin{1},varargin{2});
		case 'stimVideo'
			if length(varargin)<2, disp(['Error: not enough arguments for func ' func]);return;end
			stimVideo(varargin{1},varargin{2});
		otherwise
			disp([func ' is not a defined function']);
    end
 
	%% Subfunction: initialize()
	%   Initializes psychtoolbox components
	%	Currently includes initialization of: 
	%		PsychSound, Screen
	function [wPtr,rect,ifi,oldEnableFlag] = initialize(screenNum)
		java; %clear java cache
		KbName('UnifyKeyNames');
		warning('off','MATLAB:dispatcher:InexactMatch');
		AssertOpenGL;
		% Screen preferences
        Screen('Preference','VisualDebugLevel', 0);
		suppress_warnings = 1; % You don't need to do this but I don't like the warning screen at the beginning.
		oldEnableFlag = Screen('Preference', 'SuppressAllWarnings', suppress_warnings);
		Screen('Preference', 'TextRenderer', 0);
		Screen('Preference', 'SkipSyncTests', 1);%RLS
		% Open screen.
        %screenNum=1;
		[wPtr,rect]=Screen('OpenWindow',screenNum,1);
		ifi = Screen('GetFlipInterval', wPtr);
		%PsychSound
		InitializePsychSound;
	end
 
    %% Subfunction: [key, rt] = waitPoint(t)
	%   Inputs:  t = time to wait in seconds
	%   Outputs: key = button pressed during wait time
	%            rt = timing of button press
	function [key, rt] = waitFor(t,kbIdx,escapeKey)
		key=0;rt=0;init=0;
		if isequal(t,'TRIGGER'), t=inf;init=1;end
        trigger = [KbName('5%') KbName('=+') KbName('+') KbName('space')]; % What key triggers the script from the scanner.
        keyNames=KbName('KeyNames');
        startTime=GetSecs;
        pressed=0;
        while GetSecs<t 
            [keyIsDown, ~, keyCode] = KbCheck(kbIdx);
            if pressed == 0 && keyIsDown == 1
                pressed=1;
                key=keyNames{keyCode==1};
                rt=GetSecs-startTime;
                %disp([key ' - ' rt]);
            end
            if init==1 
                if ismember(find(keyCode==1),trigger),break;end % break if trigger
            end
            if keyCode(KbName(escapeKey)) == 1 % press escape to exit experiment
                Screen('CloseAll');
                ShowCursor;
                error('escape!')
            end
            WaitSecs('YieldSecs',0.0001);
        end
	end

	% Subfunction: kbIdx = getKeyboardIndex()
	%   Outputs: kbIdx = index of keyboard for capturing button box input
	%            escapeKey = OS-dependant escape keyname
	function [kbIdx,escapeKey] = getKeyboardIndex()
		if IsWin, kbIdx = 0; escapeKey='ESCAPE';
		elseif IsLinux, kbIdx = 0; escapeKey='esc';
		else devices = PsychHID('devices'); kbIdx = []; escapeKey='ESCAPE'; % Mac
			for dev = 1:length(devices)
				if strcmp(devices(dev).usageName,'Keyboard'), kbIdx = [kbIdx dev]; end
			end
        end
	end

	% Subfunction: stimImage()
	%   Shows an image on screen
	%   Inputs: wPtr = screen object
	%           imgHandle = image handle in imgStim structure produced by calling (where name is the filename): 
	%       		Screen('MakeTexture', wPtr, double(imread([name '.jpg'], 'JPG')));
	%			imgStim = imgStim structure
	function stimImage(wPtr,imgHandle,imgStim)
		if isequal(imgHandle, 'WHITE')
			Screen('FillRect',wPtr,WhiteIndex(wPtr));
			Screen(wPtr, 'Flip');
        else
            if iscell(imgStim)
                Screen('DrawTexture', wPtr, imgStim{imgHandle});
                Screen(wPtr, 'Flip');
            else
                Screen('DrawTexture', wPtr, imgStim.(imgHandle));
                Screen(wPtr, 'Flip');
            end
		end
	end

	% Subfunction: stimText()
	%   Shows text on screen
	%   Inputs: wPtr = screen object
	%           str = the text to display
	%           textSize = size of text to display
	function stimText(wPtr,str,textSize)
		if nargin<3, textSize=100; end
		Screen('TextSize', wPtr , textSize);
        DrawFormattedText(wPtr,str,'center','center'); 
% 		if nargin==6, DrawFormattedText(wPtr,str,x,y,color);
%         elseif nargin==5, DrawFormattedText(wPtr,str,x,y);
%         else 
%             DrawFormattedText(wPtr,str,'center','center'); 
%         end
        Screen(wPtr, 'Flip');
	end

	% Subfunction: stimSound()
	%   Plays a sound
	%	Inputs: y = vector of sampled sound data
	%			Fs = sample rate
	function stimSound(y,Fs)
		PsychPortAudio('Close');
		pahandle = PsychPortAudio('Open',[],1,1,Fs,size(y,2));
		PsychPortAudio('FillBuffer',pahandle,y');
		PsychPortAudio('Start', pahandle);
	end
	
	% Subfunction: stimVideo()
	%   Plays a sound
	%	Inputs: y = vector of sampled sound data
	%			Fs = sample rate
	function stimVideo(y,Fs)
		
	end
end



