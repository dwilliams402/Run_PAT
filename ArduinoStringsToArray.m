function [dataArray, errorArray] = ArduinoStringsToArray(baudrate, dataRowLength, dataRowCount, xCoordinateLocation, xDisplayWidth)
    %%% Documentation
    %
    % dataArray: contains the collected data; each row represents a single data
    % point
    %
    % errors: nx3 cell array of errors, first column indicated the error row
    % (intended data point), second column contained the error type (timeout or
    % improper format), third column contains the received data
    %
    % baudrate: the baudrate at which the Arduino is operating
    %
    % dataRowLength: the number of distinct data elements collected at each
    % time point (e.g. a single time and voltage set would be 2)
    %
    % dataRowCount: the maximum number of data points to be stored in the
    % output array
    %
    % xCoordinateLocation: the data point element number to be used as the x
    % -coordinate; choose 0 if the row number should be used (no x-coordinate
    % within the data)
    %
    % xDisplayWidth: the width of the displayed portion of the x axis in the real-time
    % plot in units of array elements (e.g. 50 would plot 50 datapoints in
    % series)
    %
    % For my string output Arduino EMG code, try these initial settings:
    % baudrate: 250000
    % dataRowLength: 2 (multiply this by the number of analog/mux inputs if you
    % use more than 1)
    % dataRowCount: 10000 (for test run, but change as needed)
    % xCoordinateLocation: 0
    % xDisplayWidth: somewhere between 1000 and 10000 should work well
    %
    % For my string output Arduino ECG/PAT code, try these initial settings:
    % baudrate: 115200
    % dataRowLength: 3
    % dataRowCount: 10000 (for test run, but change as needed)
    % xCoordinateLocation: 3
    % xDisplayWidth: somewhere between 1000 and 10000 should work well
    %%%
    
    % Check input count
    if nargin~=5
        disp("Not enough input arguments");
        return
    end
    
    % Select USB Port
    usbPorts = serialportlist('all');
    [index, tf] = listdlg('ListSize', [400,300], 'PromptString', 'Choose a Serial Port', 'ListString', usbPorts);
    if tf
        usbPortName = usbPorts(index);
    else
        return;
    end

    % Initialize output and row position
    dataArray = zeros(dataRowCount, dataRowLength);
    dataRow = 1;

    % Set up serial (usb) connection and initialize (consecutive) timeout count
    % and errorArray
    arduino = serialport(usbPortName, baudrate, "Timeout", 5);
    timeouts = 0;
    errorArray = cell(10000,3);
    errorRow = 1;

    % Initialize timer
    tic;
    
    % Loop until all data collected or maximum number of timeouts exceeded
    while timeouts < 5 && dataRow <= dataRowCount

        % Read a single line (data point) from the Arduino
        line = readline(arduino);

        % Check that the line isn't empty (timeout)
        if isstring(line)

            % Received data --> reset timeouts
            timeouts = 0;

            % Split data into relevant pieces and convert to each piece to a
            % number (double)
            data = str2double(split(line, ','));

            % Check that the data element count is correct
            if length(data) == dataRowLength

                % Assign data to dataArray at proper location
                dataArray(dataRow, :) = data;
        
                %Live Plot if display width provided and enough time has elapsed
                %(0.1 seconds)
                if xDisplayWidth > 0 && toc >= 0.1
                    tic;
                    LivePlot(1, dataArray, xCoordinateLocation, xDisplayWidth, dataRow - 1);
                end

                % Increment dataRow
                dataRow = dataRow + 1;
            elseif length(data) < dataRowLength

                % Missing data: improperly formatted and possibly a timeout
                errorArray(errorRow,:) = {dataRow, 'improper format and possible timeout', data};
                errorRow = errorRow + 1;
            else

                % Extraneous data: improperly formatted
                errorArray(errorRow,:) = {dataRow, 'improper format', data};
                errorRow = errorRow + 1;
            end
        else

            % No data --> timeout
            % Track timeout and associated error
            timeouts = timeouts + 1;
            errorArray(errorRow,:) = {dataRow, 'timeout', NaN};
            errorRow = errorRow + 1;
        end
    end

    % Trim dataArray and errorArray to actual size of collected information
    dataArray = dataArray(1:dataRow-1,:);
    errorArray = errorArray(1:errorRow-1,:);

end

%%LivePlot
function LivePlot(figNumber, columnData, xColumn, xDisplayWidth, stopRowIndex)
    if stopRowIndex > 1
        
        % Set figure
        figure(figNumber)

        % Plot
        xs=[]; ys=[]; startIndex=1;
        if xColumn == 0
            xs = max(1,stopRowIndex-xDisplayWidth):stopRowIndex;
            ys = columnData(xs,:);
        else
            yColumns = 1:size(columnData,2);
            yColumns(xColumn) = [];
            xs = columnData(1:stopRowIndex,xColumn);
            startIndex = find(xs>(xs(end) - xDisplayWidth));
            if isempty(startIndex)
                startIndex = 1;
            else
                startIndex = startIndex(1);
            end
            xs = xs(startIndex:end);
            ys = columnData(startIndex:stopRowIndex,yColumns);
        end
        plot(xs(startIndex:end), ys(startIndex:end,:));
        xlim([xs(end) - xDisplayWidth, xs(end)]);
        
    end
end

