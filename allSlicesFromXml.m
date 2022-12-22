function sliceArray = allSlicesFromXml(xmlInfoPath, opts)
% sliceArray = allSlicesFromXml(xmlInfoPath, opts)
% 
% xmlInfoPath - Full path to an .xml info file
% 
% opts
% verbose (logical): if true prints loading messages

arguments
    xmlInfoPath
    opts.verbose {isscalar,islogical} = true
end

% Load all images as slice objects
s = readstruct(xmlInfoPath);
names = [s.slices.name];

% Initialize the array of objects
sliceArray = Slice.empty(length(names),0);

% Load each slice 
for i = 1:length(names)
    sliceArray(i) = Slice(names(i), xmlInfoPath);
    if opts.verbose
        fprintf('Loaded slice: "%s" (%u/%u)\n', sliceArray(i).name, i, length(names))
    end
end

% Print a finish message
if opts.verbose
    fprintf('All loaded!\n')
end