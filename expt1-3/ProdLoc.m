% Function call: ProdLoc(subjID, list, order, run)
%                eg. ProdLoc('debug', 1, 1, 1)
%                for practice, pass 0 for list and 'practice' for run
%
% RUNTIME: 204 sec (3 min 24 sec)
%          runs 10x faster if subjID is 'debug'
%
% Inputs:
%   -subjID: string of subject ID (eg. 'subj01')
%   -list:   1-2, subset of materials to use (0 for practice run)
%   -order:  1-12, determines condition block orders
%   -run:    1-6 (or 'practice')
%
% Output:
%   -csv containing subject and run information
%       (data/ProdLoc_subjID_list_order_run_data.csv)
%
% Go to DISPLAY OPTIONS section to change things like font/image size
%
%
% 2015-12-03: created (Zach Mineroff - zmineroff@gmail.com)
%             Though a good chunk of this is stolen from
%                * Walid Bendris - wbendris@mit.edu
%                * Brianna Pritchett - bpritche@mit.edu
%
% 2016-01-27: updated (ZM)
%            * collect responses during entire trial, including ITI
%            * increase timing of the trials
%            * slow down movement speed of stimuli
%
% 2019-01-02: updated (Jennifer Hu - jennhu@mit.edu)
%            * modified for language production localizer

function ProdLoc(subjID, list, order, run)
    %% Make sure inputs are valid
    %subjID is a string
	assert(ischar(subjID), 'subjID must be a string');

    %order is 1 - 12
    assert(ismember(order, 1:12), 'order must be an int between 1 and 12');

    %run is 1 - 6
    if strcmp(run, 'practice')
        assert(list==0, 'list must be 0 for practice run');
    else
        assert(ismember(run, 1:6), ...
               'run must be an int between 1 and 6');
        assert(ismember(list, 1:2), ...
               'list must be 1 or 2 for non-practice run');
    end


    %% Make sure we don't accidentally overwrite a data file
	DATA_DIR = fullfile(pwd, 'data');
    if strcmp(run, 'practice')
        fileToSave = ['ProdLoc_' subjID '_practice_order' num2str(order) '_data.csv'];
    else
        fileToSave = ['ProdLoc_' subjID '_list' num2str(list) '_order' num2str(order) '_run' num2str(run) '_data.csv'];
    end
    fileToSave = fullfile(DATA_DIR, fileToSave);

	% Error message if data file already exists (unless debug mode).
	if exist(fileToSave,'file') && ~strcmpi(subjID, 'debug')
        str = input('The data file already exists for this subject! Overwrite? (y/n)','s');
        if ~isequal(str,'y')
            error('myfuns:EventsRev:DataFileAlreadyExists', ...
                  'The data file already exists for this subject!');
        end
	end


    %% Set experiment constants
    if strcmp(run, 'practice')
        %Number of events
        NUM_BLOCKS       = 6; %Number of non-fixation blocks
        TRIALS_PER_BLOCK = 4; %For a non-fixation block
        NUM_FIX          = 1; %Number of fixation blocks

        %Timing (in seconds)
        FIX_DUR      = 6;   %Length of fixation
        INSTRUCT_DUR = 2;   %Length of instructions screen
        TRIAL_DUR    = 3;   %Length of trial
        STIM_DUR     = 2.8; %Length of stimulus presentation (rest of trial is +)
        ITI          = 0;   %Inter-trial interval
    else
        %Number of events
        NUM_BLOCKS       = 12; %Number of non-fixation blocks
        TRIALS_PER_BLOCK = 4;  %For a non-fixation block
        NUM_FIX          = 3;  %Number of fixation blocks

        %Timing (in seconds)
        FIX_DUR      = 12;  %Length of fixation
        INSTRUCT_DUR = 2;   %Length of instructions screen
        TRIAL_DUR    = 3;   %Length of trial
        STIM_DUR     = 2.8; %Length of stimulus presentation (rest of trial is +)
        ITI          = 0;   %Inter-trial interval
    end

    %Make the experiment run faster if subjID is 'debug'
    if strcmpi(subjID, 'debug')
        scale = 0.3;
        FIX_DUR = FIX_DUR * scale;
        INSTRUCT_DUR = INSTRUCT_DUR * scale;
        TRIAL_DUR = TRIAL_DUR * scale;
        ITI = ITI * scale;
    end


    %% Set up condition ordering
    %The names of each block
	A = 'SPROD';
    B = 'EVSEM';
    C = 'WPROD';
    D = 'SCOMP';
    E = 'WCOMP';
    F = 'ARTIC';
    Fix = 'Fix';

    if strcmp(run, 'practice')
        %Only one block per condition, and no final fixation
        orders = {Fix, A, B, C, D, E, F;
                  Fix, B, C, D, E, F, A;
                  Fix, C, D, E, F, A, B;
                  Fix, D, E, F, A, B, C;
                  Fix, E, F, A, B, C, D;
                  Fix, F, A, B, C, D, E;
                  Fix, F, E, D, C, B, A;
                  Fix, A, F, E, D, C, B;
                  Fix, B, A, F, E, D, C;
                  Fix, C, B, A, F, E, D;
                  Fix, D, C, B, A, F, E;
                  Fix, E, D, C, B, A, F};
    else
        %The possible orders the blocks will be presented in
        orders = {Fix, A, B, C, D, E, F, Fix, F, E, D, C, B, A, Fix;
                  Fix, B, C, D, E, F, A, Fix, A, F, E, D, C, B, Fix;
                  Fix, C, D, E, F, A, B, Fix, B, A, F, E, D, C, Fix;
                  Fix, D, E, F, A, B, C, Fix, C, B, A, F, E, D, Fix;
                  Fix, E, F, A, B, C, D, Fix, D, C, B, A, F, E, Fix;
                  Fix, F, A, B, C, D, E, Fix, E, D, C, B, A, F, Fix;
                  Fix, F, E, D, C, B, A, Fix, A, B, C, D, E, F, Fix;
                  Fix, A, F, E, D, C, B, Fix, B, C, D, E, F, A, Fix;
                  Fix, B, A, F, E, D, C, Fix, C, D, E, F, A, B, Fix;
                  Fix, C, B, A, F, E, D, Fix, D, E, F, A, B, C, Fix;
                  Fix, D, C, B, A, F, E, Fix, E, F, A, B, C, D, Fix;
                  Fix, E, D, C, B, A, F, Fix, F, A, B, C, D, E, Fix};
    end
              
    %blocks is the order the blocks will be presented in for this run
	blocks = orders(order, :);


    %% Read in and organize the stimuli materials
    %Read in all materials
    if strcmp(run, 'practice')
        materials_filename = 'ProdLoc_materials_practice_run.csv';
    else
        materials_filename = 'ProdLoc_materials.csv';
    end
    materials = readtable(materials_filename, 'Delimiter', ',');

    %Extract only the materials for the given list
    list_rows = materials.List == list;
    materials = materials(list_rows, :);
    
    %Extract only the unseen items for the given subject
    if run > 1
        existing_subject_data = dir(sprintf('data/ProdLoc_%s*', subjID));
        for k=1:length(existing_subject_data)
            data_filename = existing_subject_data(k);
            materials_seen = readtable(fullfile('data', data_filename.name), 'Delimiter', ',');
            seen = strcat(materials_seen.Condition, materials_seen.Item);
            all = strcat(materials.Condition, materials.Item);
            [unseen_rows, indices] = setdiff(all, seen);
            materials = materials(indices, :);
            fprintf('Removed seen stimuli from %s\n', data_filename.name);
        end
    end

    %Determine which rows in the materials table correspond to different
    %stimulus types
    sprod_pic_rows  = strcmp(materials.Condition, 'SPROD');  % SPROD
    evsem_pic_rows  = strcmp(materials.Condition, 'EVSEM');  % EVSEM
    obj_set_rows = strcmp(materials.Condition, 'WPROD'); % WPROD
    sent_rows = strcmp(materials.Condition, 'SCOMP'); % SCOMP
    w_list_rows = strcmp(materials.Condition, 'WCOMP');   % WCOMP
    nw_list_rows = strcmp(materials.Condition, 'ARTIC'); % ARTIC

    SPRODPic = materials(sprod_pic_rows, :);
    EVSEMPic = materials(evsem_pic_rows, :);
    ObjSet   = materials(obj_set_rows, :);
    Sent     = materials(sent_rows, :);
    WList    = materials(w_list_rows, :);
    NWList   = materials(nw_list_rows, :);

    %% Randomly select which materials to use for each condition
    % A given stimulus will be used in a maximum of 1 condition,
    % EXCEPT in the SPROD and EVSEM conditions

    if strcmp(run, 'practice')
        mult = 1;
    else
        mult = 2;
    end
    
    %SPROD
        %4 random pictures
        rand_rows = randperm(height(SPRODPic), mult*TRIALS_PER_BLOCK)';
        SPROD = SPRODPic(rand_rows, :);
        SPRODPic(rand_rows, :) = []; % delete the chosen pictures
                                     % so we don't use them again

    %EVSEM
        %4 random pictures
        rand_rows = randperm(height(EVSEMPic), mult*TRIALS_PER_BLOCK)';
        EVSEM = EVSEMPic(rand_rows, :);
        EVSEMPic(rand_rows, :) = []; 
        
    %WPROD
        %4 random object sets
        rand_rows = randperm(height(ObjSet), mult*TRIALS_PER_BLOCK)';
        WPROD = ObjSet(rand_rows, :);
        ObjSet(rand_rows, :) = [];

    %SCOMP
        %4 random sentences
        rand_rows = randperm(height(Sent), mult*TRIALS_PER_BLOCK)';
        SCOMP = Sent(rand_rows, :);
        Sent(rand_rows, :) = [];

    %WCOMP
        %4 random word lists
        rand_rows = randperm(height(WList), mult*TRIALS_PER_BLOCK)';
        WCOMP = WList(rand_rows, :);
        WList(rand_rows, :) = [];

    %ARTIC
        %4 random nonword lists
        rand_rows = randperm(height(NWList), mult*TRIALS_PER_BLOCK)';
        ARTIC = NWList(rand_rows, :);
        NWList(rand_rows, :) = [];

	% the tables Pic, ObjSet, Sent, WList, and NWList
	% now only contain UNUSED materials


	%% Randomize the order of the materials
    SPRODPic = randomizeTable(SPRODPic);
    EVSEMPic = randomizeTable(EVSEMPic);
    ObjSet   = randomizeTable(ObjSet);
    Sent     = randomizeTable(Sent);
    WList    = randomizeTable(WList);
    NWList   = randomizeTable(NWList);


    %% Set up the data that we want to save
    numTrials = (NUM_BLOCKS * TRIALS_PER_BLOCK) + NUM_FIX;

    resultsHdr = {'SubjID','List','Order','Run', ...
                  'TrialNumber', 'TrialOnset', ...
                  'Condition', 'ItemNum', 'Item', ...
                  'Response', 'RT'};
     
    %results is the table that will hold all of the data we want to save
    results = cell(numTrials, length(resultsHdr));
    results = cell2table(results, 'VariableNames', resultsHdr);

    %Fill in the user input information
    results.SubjID(:) = {subjID};
    results.List  = ones(numTrials,1)*list;
    results.Order = ones(numTrials,1)*order;
    if strcmp(run, 'practice')
        C    = cell(numTrials,1);
        C(:) = {'practice'};
        results.Run = C;
    else
        results.Run = ones(numTrials,1)*run;
    end

    %Fill in the info we already know
    results.TrialNumber = (1:numTrials)';

    %Enter 0 as the default value for the data that we'll fill in as we go
    filler_data = zeros(numTrials,1);
    results.TrialOnset = filler_data;
    results.ItemNum    = filler_data;
    results.Response   = filler_data;
    results.RT         = filler_data;

    trialNum = 1;
    for block = blocks  
        %Fill in info for fixation blocks
        if strcmp(block, 'Fix')
            results.Condition(trialNum) = {'FIX'};
            results.Item(trialNum) = {'+'};
            trialNum = trialNum + 1;
            continue
        end

        %Fill in info for trial blocks
        if strcmp(block, 'SPROD'),     cond_table = SPROD;
        elseif strcmp(block, 'EVSEM'), cond_table = EVSEM;
        elseif strcmp(block, 'WPROD'), cond_table = WPROD;
        elseif strcmp(block, 'SCOMP'), cond_table = SCOMP;
        elseif strcmp(block, 'WCOMP'), cond_table = WCOMP;
        else                           cond_table = ARTIC;
        end
        %HACK: need to update index for trials after middle fixation
        %(not sure why EventsRev code didn't work for this)
         midpoint = (NUM_FIX-1) + TRIALS_PER_BLOCK * (NUM_BLOCKS/2);
         if trialNum <= midpoint || strcmp(run, 'practice')
             base = 0;
         else
             base = TRIALS_PER_BLOCK;
         end
        for i=1:TRIALS_PER_BLOCK
            %General trial information
            results.Condition(trialNum) = block;
            results.ItemNum(trialNum)   = cond_table.ItemNum(i+base);
            results.Item(trialNum)      = cond_table.Item(i+base);

            trialNum = trialNum + 1;
        end
    end


	%% Set up screen and keyboard for Psychtoolbox
    %Screen
%     if strcmp(subjID, 'debug')
%         PsychDebugWindowConfiguration
%     end
    screenNum = max(Screen('Screens'));  %Highest screen number is most likely correct display
    windowInfo = PTBhelper('initialize',screenNum);

    %UNCOMMENT FOR REAL EXPT
    wPtr = windowInfo{1}; %pointer to window on screen that's being referenced
    rect = windowInfo{2}; %dimensions of the window
    winWidth = rect(3);
    winHeight = rect(4);


    disp(rect)
    rect = rect/2;
    disp(rect)
    oldEnableFlag = windowInfo{4};
    HideCursor;
    PTBhelper('stimImage',wPtr,'WHITE');


%     if strcmp(subjID, 'debug')
%         [wPtr, rect] = openDebugWindow(screenNum, rect_orig);
%         winWidth = rect(3);
%         winHeight = rect(4);
%     end

    PTBhelper('stimText',wPtr,'Loading experiment\n\n(Don''t start yet!)',30);

    %Keyboard
    keyboardInfo = PTBhelper('getKeyboardIndex');
    kbIdx = keyboardInfo{1};
    escapeKey = keyboardInfo{2};


    %% Set display options
    %Font sizes
    sentFontSize = 40;      %stimuli sentences
    instructFontSize = 30;  %instructions screen before each block
    helpFontSize = 20;      %instructions that appear during each trial
    fixFontSize = 40;       %fixation cross

    %Image size (pixels)
    imgHeight = 512;   %image width is automatically scaled

    %Instructions (presented before each block)
    SPROD_instruct = 'Describe the event out loud.';
    EVSEM_instruct = 'Indoors (=1) or outdoors (=2)?';
    WPROD_instruct = 'Name the objects out loud.';
    SCOMP_instruct = 'Read the sentence silently.';
    WCOMP_instruct = 'Read the words silently.';
    ARTIC_instruct = 'Say the nonwords out loud.';

    %Help instructions position (pixels)
    helpPosX = 50;  %distance from left of screen
    helpPosY = 900; %distance from top of screen

	%% Put some variables into structs to help send them to the animate functions
    displayOptions = struct('sentFontSize', sentFontSize, ...
                            'instructFontSize', instructFontSize, ...
                            'helpFontSize', helpFontSize, ...
                            'imgHeight', imgHeight);

    winInfo = struct('wPtr', wPtr, ...
                     'winWidth', winWidth, ...
                     'winHeight', winHeight);

	keyInfo = struct('kbIdx', kbIdx, ...
                     'escapeKey', escapeKey);

	%Can make something like checkDimensions(display_options) to make sure
    %helpScreen is ok, font sizes all fit, image height is ok, etc
%     if helpPosX > winWidth
%         Screen('CloseAll');
%         ShowCursor;
%         fprintf('\nHelp screen x dimension is set out of window boundaries\n')
%     end


    %% Set up images
    if strcmp(run, 'practice')
        PIC_DIR = fullfile(pwd, '../SProd/stimuli/practice');
        OBJSET_DIR = fullfile(pwd, '../WProd/stimuli/practice');
    else
        PIC_DIR = fullfile(pwd, '../SProd/stimuli');
        OBJSET_DIR = fullfile(pwd, '../WProd/stimuli');
    end

    %This is the bottleneck in loading the experiment
    %Maybe decreasing the resolution of the images will help
    fprintf('Loading SPROD images\n');
    SPROD_imgs = loadImages(wPtr, PIC_DIR, SPROD.Item,  imgHeight);
    fprintf('Loading EVSEM images\n');
    EVSEM_imgs = loadImages(wPtr, PIC_DIR, EVSEM.Item, imgHeight);
    fprintf('Loading WPROD images\n');
    WPROD_imgs = loadImages(wPtr, OBJSET_DIR, WPROD.Item, imgHeight);


    %% Set up help screen
    helpRect = rect;

    %Move the help screen right
    helpRect(1) = helpRect(1) + helpPosX;
    helpRect(3) = helpRect(3) + helpPosX;

    %Move the help screen down
    helpRect(2) = helpRect(2) + helpPosY;
    helpRect(4) = helpRect(4) + helpPosY;


    helpPtr = Screen('OpenWindow',screenNum, 1, helpRect);
    PTBhelper('stimImage',helpPtr,'WHITE');


    %% Present the experiment
    RestrictKeysForKbCheck([]);
    enableKeys = [KbName('1'), KbName('1!'), KbName('2'), KbName('2@'), KbName(escapeKey)];

	% Wait indefinitely until trigger
    PTBhelper('stimText',wPtr,'Waiting for trigger...',sentFontSize);
    PTBhelper('waitFor','TRIGGER',kbIdx,escapeKey);

    RestrictKeysForKbCheck(enableKeys);

    trialNum = 1;
    runOnset = GetSecs; %remains the same
    onset = runOnset;   %updates for each trial

    %Present each block
    try
        for block = blocks
            %Fixation
            if strcmp(block, 'Fix')
                %Show fixation cross
                PTBhelper('stimText', wPtr, '+', fixFontSize);
                trialEndTime = onset + FIX_DUR;
                PTBhelper('waitFor',trialEndTime,kbIdx,escapeKey);

                %Save data
                results.TrialOnset(trialNum) = onset - runOnset;

                %Update loop variables
                trialNum = trialNum + 1;
                onset = trialEndTime;

                continue
            end

            %If it's not fixation, determine which instructions and table to use for the trial

            %SPROD
            if strcmp(block, 'SPROD')
                instructions = SPROD_instruct;
                help = SPROD_instruct;
                cond_table = SPROD;
                cond_imgs = SPROD_imgs;

            %EVSEM
            elseif strcmp(block, 'EVSEM')
                instructions = EVSEM_instruct;
                help = EVSEM_instruct;
                cond_table = EVSEM;
                cond_imgs = EVSEM_imgs;

           	%WPROD
            elseif strcmp(block, 'WPROD')
                instructions = WPROD_instruct;
                help = WPROD_instruct;
                cond_table = WPROD;
                cond_imgs = WPROD_imgs;

            %SCOMP
            elseif strcmp(block, 'SCOMP')
                instructions = SCOMP_instruct;
                help = SCOMP_instruct;
                cond_table = SCOMP;

            %WCOMP
            elseif strcmp(block, 'WCOMP')
                instructions = WCOMP_instruct;
                help = WCOMP_instruct;
                cond_table = WCOMP;

            %ARTIC
            else
                instructions = ARTIC_instruct;
                help = ARTIC_instruct;
                cond_table = ARTIC;
            end

            %Show instructions
            PTBhelper('stimText', wPtr, instructions, instructFontSize);
            instructEndTime = onset + INSTRUCT_DUR;
            PTBhelper('waitFor',instructEndTime,kbIdx,escapeKey);
            onset = instructEndTime;

            %Show help
            Screen('TextSize', helpPtr , helpFontSize);
            DrawFormattedText(helpPtr,help, 0, 0);
            Screen(helpPtr, 'Flip');

            %Show each trial
            for i=1:TRIALS_PER_BLOCK
                %Get the trial end time
                trialEndTime = onset + TRIAL_DUR + ITI;

                %Show fixation cross
                PTBhelper('stimText', wPtr, '+', fixFontSize);
                fixEndTime = trialEndTime - STIM_DUR;
                PTBhelper('waitFor',fixEndTime,kbIdx,escapeKey);

                %animate the image or text
                conds_with_img = {'SPROD', 'EVSEM', 'WPROD'};
                if any(strcmp(conds_with_img, block))
                     [response, rt] = animateImage(winInfo, keyInfo, ...
                                                   displayOptions, ...
                                                   cond_table, cond_imgs, ...
                                                   i, onset, trialEndTime, ITI);

                else
                     [response, rt] = animateText(winInfo, keyInfo, ...
                                                  displayOptions, ...
                                                  cond_table, ...
                                                  i, onset, trialEndTime, ITI);
                end

                %Save data
                results.TrialOnset(trialNum) = onset - runOnset;
                results.Response(trialNum) = response;
                results.RT(trialNum) = rt;


                %Update loop variables
                trialNum = trialNum+1;
                %onset = blankEndTime;
                onset = trialEndTime;
            end

            %Hide help
            PTBhelper('stimImage',helpPtr,'WHITE');

            %Remove used stimuli
            if strcmp(block, 'SPROD')
                SPROD(1:TRIALS_PER_BLOCK, :) = [];
                SPROD_imgs(1:TRIALS_PER_BLOCK, :) = [];

            elseif strcmp(block, 'EVSEM')
                EVSEM(1:TRIALS_PER_BLOCK, :) = [];
                EVSEM_imgs(1:TRIALS_PER_BLOCK, :) = [];

            elseif strcmp(block, 'WPROD')
                WPROD(1:TRIALS_PER_BLOCK, :) = [];
                WPROD_imgs(1:TRIALS_PER_BLOCK, :) = [];

            elseif strcmp(block, 'SCOMP')
                SCOMP(1:TRIALS_PER_BLOCK, :) = [];

            elseif strcmp(block, 'WCOMP')
                WCOMP(1:TRIALS_PER_BLOCK, :) = [];

            else
                ARTIC(1:TRIALS_PER_BLOCK, :) = [];
            end
        end

        %runtime = GetSecs - runOnset;

        %Save all data
        writetable(results, fileToSave);

        Screen('CloseAll');
        ShowCursor;

    catch errorInfo
        %runtime = GetSecs - runOnset;

        %Save all data
        writetable(results, fileToSave);

        Screen('CloseAll');
        ShowCursor;
        fprintf('%s%s\n', 'error message: ', errorInfo.message)
    end

    %Restore the old level.
    Screen('Preference','SuppressAllWarnings',oldEnableFlag);
    RestrictKeysForKbCheck([]);
end




%% RandomizeTable
%Randomizes the order of the rows in table table_in
%Doesn't allow more than maxReps of any item in constraint_variable to appear in a row
function [randomized_table] = randomizeTable(table_in, constraint_variable, maxReps)
    numItems = height(table_in);

    %Shuffle the materials randomly
    randomized_table = table_in(randperm(numItems), :);

    %JH 2018-01-02: constraint_variable and maxReps are optional
    if nargin == 3
        %If there are more than maxReps of the constraint_variable in a row,
        %randomize the materials table again. Repeat as necessary.
        while ~checkMaxReps(randomized_table{:,{constraint_variable}}, maxReps)
            randomized_table = table_in(randperm(numItems), :);
        end
    end
end



%% checkMaxReps
%isShuffled is true if the given cell array contains no more than maxReps
%items in a row anywhere in the array. False otherwise.
function [isShuffled] = checkMaxReps(cell_array, maxReps)
    %if given cell array is an array of doubles, convert it to a cell array
    %of strings
    if isnumeric(cell_array)
        cell_array = cellstr(num2str(cell_array));
    end

    %Initialize isShuffled to true
    isShuffled = true;

    %isShuffled is true if the length of cell_array
    %is less than or equal to maxReps
    numElts = length(cell_array);
    if numElts <= maxReps
        return
    end

    %Loop through cell_array to see if there are more than maxReps
    %repetitions. Set isShuffled to false if there are.
    for i = (maxReps+1):numElts
        stringToCompare = cell_array(i);
        sub_array = cell_array(i-maxReps:i-1);

        if all(strcmp(sub_array, stringToCompare))
            isShuffled = false;
            return
        end
    end
end



%% AssignDirections
%Adds the variable Left_Right to the last column of table_in
%Each row of Left_Right is randomly chosen to be 'left' or 'right'
function [new_table] = assignDirections(table_in)
    numRows = height(table_in);
    Left_Right = cell(numRows, 1);

    %An array of random 1's and 0's
    coinToss = round(rand(1,numRows))';

    Left_Right(coinToss==0) = {'left'};
    Left_Right(coinToss==1) = {'right'};

    new_table = [table_in table(Left_Right)];
end




%% loadImages
%wPtr: window pointer
%pics_dir: path to folder that contains images
%filenames: cell array of filenames (ex: 'stimuli_1.jpg')
%imgHeight: height you want the images to be in pixels
%           width is automatically scaled
function [images] = loadImages(wPtr, pics_dir, filenames, imgHeight)
    %Store the images in this cell array
    images = cell(length(filenames), 1);

    %The full paths to all the pictures
    image_paths = fullfile(pics_dir, filenames);

    for i=1:length(filenames);
        image_path = image_paths{i};

        try
            image = imread(image_path, 'JPG');
        catch errorInfo
            showImreadError(errorInfo, image_path);
            return
        end

        image = imresize(image, [imgHeight NaN]);
        images{i} = Screen('MakeTexture', wPtr, image);
    end
end




%% animateImage
%Moves an image left or right
%Returns what key was pressed as well as the reaction time
function [response, rt] = animateImage(winInfo, keyInfo, displayOptions, ...
                                       cond_table, cond_imgs, ...
                                       stimIdx, onset, trialEndTime, ITI)
    %I don't like using dots all over the place
    %winInfo
        wPtr = winInfo.wPtr;
        winHeight = winInfo.winHeight;
        winWidth = winInfo.winWidth;
	%keyInfo
        kbIdx = keyInfo.kbIdx;
        escapeKey = keyInfo.escapeKey;
        keyNames = KbName('KeyNames');
    %displayOptions
        imgHeight = displayOptions.imgHeight;
%         speed = displayOptions.image_speed;


    %The real function starts here
    stimulus = cond_imgs{stimIdx};

    %Get the width of the image
    imgWidth = Screen('WindowSize', stimulus);

    %Set the start position for the stimulus (center)
    destRect = [winWidth/2  - imgWidth/2,  ... %left
                winHeight/2 - imgHeight/2, ... %top
                winWidth/2  + imgWidth/2,  ... %right
                winHeight/2 + imgHeight/2];    %bottom

    %Initialize response and reaction time to 0
    response = 0;
    rt = 0;
    pressed = 0;  %changes to 1 when a button is pressed

    %Show the stimulus
    Screen('DrawTexture', wPtr, stimulus, [], destRect);
    Screen(wPtr, 'Flip');

    while GetSecs < trialEndTime-ITI
        %Check for a button press
        [keyIsDown, ~, keyCode] = KbCheck(kbIdx);
        if pressed == 0 && keyIsDown == 1
            pressed = 1;
            response = keyNames{keyCode==1};
            rt = GetSecs - onset;

            if ischar(response)
                response = sscanf(response, '%d');
            end
        end

        %Exit the experiment if escape key is pressed
        if keyCode(KbName(escapeKey)) == 1
            Screen('CloseAll');
            ShowCursor;
            error('escape!')
        end

        %Move the position of the stimulus left or right
%         if strcmp(cond_table.Left_Right{stimIdx}, 'left')
%             destRect(1) = destRect(1) - speed;
%             destRect(3) = destRect(3) - speed;
%         else
%             destRect(1) = destRect(1) + speed;
%             destRect(3) = destRect(3) + speed;
%         end

        Screen('DrawTexture', wPtr, stimulus, [], destRect);
        Screen(wPtr, 'Flip');

        WaitSecs('YieldSecs',0.0001);
    end

    %Blank ITI
    PTBhelper('stimText', wPtr, ' ');
    while GetSecs < trialEndTime
        %Check for a button press
        [keyIsDown, ~, keyCode] = KbCheck(kbIdx);
        if pressed == 0 && keyIsDown == 1
            pressed = 1;
            response = keyNames{keyCode==1};
            rt = GetSecs - onset;

            if ischar(response)
                response = sscanf(response, '%d');
            end
        end

        %Exit the experiment if escape key is pressed
        if keyCode(KbName(escapeKey)) == 1
            Screen('CloseAll');
            ShowCursor;
            error('escape!')
        end
    end
end



%% animateText
%Moves text left or right
%Returns what key was pressed as well as the reaction time
function [response, rt] = animateText(winInfo, keyInfo, displayOptions, ...
                                      cond_table, stimIdx, onset, ...
                                      trialEndTime, ITI)
	%I don't like using dots all over the place
    %winInfo
        wPtr = winInfo.wPtr;
        winHeight = winInfo.winHeight;
        winWidth = winInfo.winWidth;
	%keyInfo
        kbIdx = keyInfo.kbIdx;
        escapeKey = keyInfo.escapeKey;
        keyNames = KbName('KeyNames');
    %displayOptions
        sentFontSize = displayOptions.sentFontSize;
%         speed = displayOptions.sent_speed;

	%The real function starts here
    stimulus = cond_table.Item{stimIdx};

    %Set the start position for the stimulus (center)
    destRect = [winWidth/2,  ... %left
                winHeight/2, ... %top
                winWidth/2,  ... %right
                winHeight/2];    %bottom

    %Initialize response and reaction time to 0
    response = 0;
    rt = 0;
    pressed = 0;  %changes to 1 when a button is pressed

    %Show the stimulus
    Screen('TextSize', wPtr , sentFontSize);
    DrawFormattedText(wPtr, stimulus, 'center', 'center', ...
                      [], [], [], [], [], [], destRect);
    Screen(wPtr, 'Flip');

    while GetSecs < trialEndTime-ITI
        %Check for a button press
        [keyIsDown, ~, keyCode] = KbCheck(kbIdx);
        if pressed == 0 && keyIsDown == 1
            pressed = 1;
            response = keyNames{keyCode==1};
            rt = GetSecs - onset;

            if ischar(response)
                response = sscanf(response, '%d');
            end
        end

        %Exit the experiment if escape key is pressed
        if keyCode(KbName(escapeKey)) == 1
            Screen('CloseAll');
            ShowCursor;
            error('escape!')
        end

        %Move the position of the stimulus left or right
%         if strcmp(cond_table.Left_Right{stimIdx}, 'left')
%             destRect(1) = destRect(1) - speed;
%             destRect(3) = destRect(3) - speed;
%         else
%             destRect(1) = destRect(1) + speed;
%             destRect(3) = destRect(3) + speed;
%         end

        DrawFormattedText(wPtr, stimulus, 'center', 'center', ...
                      [], [], [], [], [], [], destRect);
        Screen(wPtr, 'Flip');

        WaitSecs('YieldSecs',0.0001);
    end


    %Blank ITI
    PTBhelper('stimText', wPtr, ' ');
    while GetSecs < trialEndTime
        %Check for a button press
        [keyIsDown, ~, keyCode] = KbCheck(kbIdx);
        if pressed == 0 && keyIsDown == 1
            pressed = 1;
            response = keyNames{keyCode==1};
            rt = GetSecs - onset;

            if ischar(response)
                response = sscanf(response, '%d');
            end
        end

        %Exit the experiment if escape key is pressed
        if keyCode(KbName(escapeKey)) == 1
            Screen('CloseAll');
            ShowCursor;
            error('escape!')
        end
    end
end



%% grade_results
function [results] = grade_results(results)
    rows_to_grade = ~strcmp(results.Condition, 'FIX');
    correct_answers = results.CorrectAnswer(rows_to_grade);
    responses = results.Response(rows_to_grade);
    accuracies = correct_answers == responses;
    results.Accuracy(rows_to_grade) = accuracies;
end



%% Debugging functions
function [wPtr, rect] = openDebugWindow(screenNum, rect_orig)
    Screen('CloseAll');
    ShowCursor;
    clear Screen

    rect = rect_orig / 2;
    rect(1) = 0;
    rect(2) = 0;


    java; %clear java cache
    KbName('UnifyKeyNames');
    warning('off','MATLAB:dispatcher:InexactMatch');
    AssertOpenGL;
    suppress_warnings = 1;
    Screen('Preference', 'SuppressAllWarnings', suppress_warnings);
    Screen('Preference', 'TextRenderer', 0);
    Screen('Preference', 'SkipSyncTests', 1);
    [wPtr,rect] = Screen('OpenWindow',screenNum,1,rect,[],[],[],[],[],kPsychGUIWindow,[]);
end



function showImreadError(errorInfo, img_filename)
    Screen('CloseAll');
    ShowCursor;

    fprintf('\nThere was a problem using imread with image stimuli:\n')
    fprintf('%s\n', img_filename)
    fprintf('\t%s%s\n', 'ERROR MESSAGE: ', errorInfo.message)
    fprintf('\tTry running incompatibleImgs() to see what files are giving you trouble.\n')
    fprintf('\tYou may want to check out: http://www.cmyk2rgb.com/\n')
end
