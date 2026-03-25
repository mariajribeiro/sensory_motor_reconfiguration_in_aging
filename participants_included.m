function group = participants_included

    % participants included in analyses

    young = {'AB100' 'AB101' 'AB102' 'AB103' 'AB062' 'AB105' 'AB099' 'AB053'...
    'AB109' 'AB110' 'AB111' 'AB076' 'AB114' 'AB117' 'AB118' 'AB120' 'AB121' 'AB122'...
    'AB123' 'AB056' 'AB125' 'AB126' 'AB127' 'AB129' 'AB134' 'AB135' 'AB139' 'AB141'...
    'AB150' 'AB151' 'AB153' 'AB158' 'AB161' 'AB162' 'AB160' 'AB169' 'AB171', 'AB175', ...
    'AB179', 'AB180', 'AB182'};

    older = {'AB104' 'AB071' 'AB058' 'AB057' 'AB067' 'AB106' 'AB107' 'AB011'...
    'AB073' 'AB108' 'AB112' 'AB079' 'AB113' 'AB075' 'AB115' 'AB116' 'AB119' 'AB091'...
    'AB124' 'AB128' 'AB130' 'AB131' 'AB132' 'AB133' 'AB136' 'AB137' 'AB138' 'AB140' 'AB142' 'AB143'...
    'AB144' 'AB145' 'AB146' 'AB147' 'AB148' 'AB149' 'AB152' 'AB154' 'AB155' 'AB156'...
    'AB157' 'AB159' 'AB163' 'AB164' 'AB165' 'AB166' 'AB167' 'AB168' 'AB170', 'AB172',...
    'AB173', 'AB174', 'AB176', 'AB177', 'AB178', 'AB181'};

    % possibly exclude 

    % 'AB075' - technical difficulties, difficulty learning the task, visual
    % problems not completely corrected with glasses
    % 'AB119' - brain injury
    % 'AB115', 'AB106', 'AB107' - medicated with betablockers
    % 'AB156' - did not understand task and decided to quit
    % 'AB166' - corpus callosum malformation 
    % 'AB151', 'AB152' - MoCA scores below cutoff

    exclude = {'AB106', 'AB107', 'AB115', 'AB119' 'AB156' 'AB075' 'AB166' 'AB151', 'AB152'};

    group = {setdiff(young, exclude), setdiff(older, exclude)};
end