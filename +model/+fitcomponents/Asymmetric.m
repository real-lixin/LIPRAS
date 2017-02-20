classdef Asymmetric < model.fitcomponents.FitFunctionInterface
  
    properties
        Name
        
        CoeffNames
        
        ID
    end
    
    properties (Hidden)
       Left % FitFunction object defining the left side function
       
       Right % FitFunction object defining the right side function
       
       DefaultFcn = 'PearsonVII';
    end
    
    
    methods
       function this = Asymmetric(id, constraints, fcnName)
       if nargin < 1
           id = 1;
       end
       if nargin < 2
           constraints = '';
       end
       if nargin < 3
           fcnName = this.DefaultFcn;
       end
       % Create left and right side components
       this.Left = model.fitcomponents.(fcnName)(id);
       this.Right = model.fitcomponents.(fcnName)(id);
       this.Name = ['Asymmetric ' this.Left.Name]; 
       % Append the coefficient names of 'N', 'w', or 'm' with 'L' or 'R'
       this.Left.CoeffNames{1}(2) = 'L';
       this.Right.CoeffNames{1}(2) = 'R';
       if length(this.Left.CoeffNames) > 3
           this.Left.CoeffNames{4}(2) = 'L';
           this.Right.CoeffNames{4}(2) = 'R';
       end
       % Make sure they're in the expected order
       coeffs = [];
       for i=1:length(this.Left.CoeffNames)
           coeffs = [coeffs {this.Left.CoeffNames{i}} {this.Right.CoeffNames{i}}]; %#ok<AGROW>
       end
       this.CoeffNames = unique(coeffs, 'stable');
       this.Left.Name = ['Left ' this.Name];
       this.Right.Name = ['Right ' this.Name];
       this.ID = id;
       this.constrain(constraints);
       end
       
       function value = getCoeffs(this)
       leftCoeffs = this.Left.getUnconstrainedCoeffs;
       rightCoeffs = this.Right.getUnconstrainedCoeffs;
       unconstrained = [];
       
       for i=1:length(leftCoeffs)
           unconstrained = [unconstrained leftCoeffs(i) rightCoeffs(i)]; %#ok<AGROW>
       end
       
       unconstrained = unique(unconstrained, 'stable');
       value = [this.ConstrainedCoeffs, unconstrained];
       end
       
       function str = getEqnStr(this, coeffs)
       if nargin < 2
           leftEqn = this.Left.getEqnStr;
           rightEqn = this.getRightEqnStr;
       else
          leftEqn = this.Left.getEqnStr(coeffs);
          rightEqn = this.Right.getEqnStr(coeffs);
       end
       leftCutoffStr = ['model.fitcomponents.Asymmetric.AsymmCutoff(x' num2str(this.ID) ',1,xv)'];
       rightCutoffStr = ['model.fitcomponents.Asymmetric.AsymmCutoff(x' num2str(this.ID) ',2,xv)'];
       str = [leftCutoffStr '*' leftEqn ' + ' rightCutoffStr '*' rightEqn];
       end
       
       function this = constrain(this, coeff)
       if ~isempty(coeff)
           constrain@model.fitcomponents.FitFunctionInterface(this.Left, coeff);
           constrain@model.fitcomponents.FitFunctionInterface(this.Right, coeff);
           constrain@model.fitcomponents.FitFunctionInterface(this, coeff);
       end
       end
       
       function this = unconstrain(this, coeff)
       if ~isempty(coeff)
           unconstrain@model.fitcomponents.FitFunctionInterface(this.Left, coeff);
           unconstrain@model.fitcomponents.FitFunctionInterface(this.Right, coeff);
           unconstrain@model.fitcomponents.FitFunctionInterface(this, coeff);
       end
       end
       
       function output = getDefaultInitialValues(this, data, peakpos)
       left = this.Left.getDefaultInitialValues(data, peakpos);
       output.N = left.N;
       output.x = left.x;
       output.f = left.f;
       if isfield(left, 'w') 
           output.w = left.w;
       elseif isfield(left, 'm')
           output.m = left.m;
       end
       end
       
       function output = getDefaultLowerBounds(this, data, peakpos)
       left = this.Left.getDefaultLowerBounds(data, peakpos);
       output.N = left.N;
       output.x = left.x;
       output.f = left.f;
       
       if isfield(left, 'w') 
           output.w = left.w;
       elseif isfield(left, 'm') 
           output.m = left.m;
       end
       end
       
       function output = getDefaultUpperBounds(this, data, peakpos)
       left = this.Left.getDefaultUpperBounds(data, peakpos);
       output.N = left.N;
       output.x = left.x;
       output.f = left.f;
       if isfield(left, 'w')
           output.w = left.w;
       elseif isfield(left, 'm') 
           output.m = left.m;
       end
       end
       
    end
    
    methods (Access = protected)
        function str = getRightEqnStr(this)
        %getRightEqnStr returns the modified equation string for an asymmetric function. In the
        %   equation, the coefficient 'f' is multiplied by 'NR/NL*C4(mR)/C4(mL)'.
        rightEqn = this.Right.getEqnStr;
        Nratio = ''; mratio = '';
        if ~this.isNConstrained
            Nratio = ['NR' num2str(this.ID) '/NL' num2str(this.ID)];
        end
        if ~this.isMConstrained
            mratio = ['model.fitcomponents.PearsonVII.C4(mR' num2str(this.ID) ')'...
                '/model.fitcomponents.PearsonVII.C4(mL' num2str(this.ID) ')'];
        end
        f = this.coeff('f');
        str = strrep(rightEqn, f, ['(' f '*' Nratio '*' mratio ')']);
        end
        
        function setPeakPosition(this, value)
        this.Left.PeakPosition_ = value;
        this.Right.PeakPosition_ = value;
        this.PeakPosition_ = value;
        end
        
        function value = getPeakPosition(this)
        value = this.Left.PeakPosition_;
        end
        
        function output = calculate_(this, xdata, coeffvals)
        %
        %
        %   FITINITIAL is a cell array of numeric values corresponding to the
        %   coefficients at the same index when GETCOEFFS is called.
        leftcoeffs = this.Left.getCoeffs;
        rightcoeffs = this.Right.getCoeffs;
        coeffNames = this.getCoeffs;
        leftCoeffIndices = zeros(1,length(leftcoeffs));
        rightCoeffIndices = zeros(1,length(rightcoeffs));
        fidx = 0;
        
        % Assuming length(leftcoeffs) == length(rightcoeffs)
        for i=1:length(leftcoeffs) 
            leftCoeffIndices(i) = find(strcmpi(coeffNames, leftcoeffs{i}),1);
            rightCoeffIndices(i) = find(strcmpi(coeffNames, rightcoeffs{i}),1);
            % Assuming leftcoeff value of x == rightcoeff value of x
            if leftcoeffs{i}(1) == 'N'
                Nidx = i;
            elseif leftcoeffs{i}(1) == 'x'
                xval = coeffvals(leftCoeffIndices(i));
            elseif leftcoeffs{i}(1) == 'f'
                fidx = i;
            elseif leftcoeffs{i}(1) == 'm'
                midx = i;
            end
        end
        lvals = coeffvals(leftCoeffIndices);
        rvals = coeffvals(rightCoeffIndices);
        rvals(fidx) = rvals(fidx) * rvals(Nidx)/lvals(Nidx) * this.Left.C4(rvals(midx)) / this.Right.C4(lvals(midx));
        leftoutput = this.Left.calculateFit(xdata, lvals);
        rightoutput = this.Right.calculateFit(xdata, rvals);
        output = leftoutput .* this.AsymmCutoff(xval, 1, xdata)' + ...
            rightoutput .* this.AsymmCutoff(xval, 2, xdata)';
        end
        
        
    end
   
    methods (Static)
        function Y = AsymmCutoff(x, side, xdata)
        numPts=length(xdata);
        step = zeros(1,numPts);
        if side == 1
            for i=1:numPts
                if xdata(i) < x
                    step(i)=1;
                else
                    step(i)=0;
                end
            end
        elseif side == 2
            for i=1:numPts
                if xdata(i) < x
                    step(i)=0;
                else
                    step(i)=1;
                end
            end
        end
        Y=step';
        end
        % ==================================================================== %
    end
    
    
end