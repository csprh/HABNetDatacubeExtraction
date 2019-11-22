function [F1,precision,recall,accuracy, kappa] = printClassMetrics (pred_val , yval)
  verbose = 1;
  accuracy = mean(double(pred_val == yval));
  acc_all0 = mean(double(0 == yval));

  actual_positives = sum(yval == 1);
  actual_negatives = sum(yval == 0);
  true_positives = sum((pred_val == 1) & (yval == 1));
  true_negatives = sum((pred_val == 0) & (yval == 0));
  false_positives = sum((pred_val == 1) & (yval == 0));
  false_negatives = sum((pred_val == 0) & (yval == 1));

  po = (true_positives+true_negatives)/(actual_positives+actual_negatives);
  ptrue = ((true_positives+false_positives)*(true_positives+false_negatives))/((actual_positives+actual_negatives)*(actual_positives+actual_negatives));
  pfalse = ((true_negatives+false_positives)*(true_negatives+false_negatives))/((actual_positives+actual_negatives)*(actual_positives+actual_negatives));
  pe = ptrue+pfalse;

  kappa = (po-pe)/(1-pe);
  precision = 0; 

  if ( (true_positives + false_positives) > 0)
    precision = true_positives / (true_positives + false_positives);
  end 

  recall = 0; 
  if ( (true_positives + false_negatives) > 0 )
    recall = true_positives / (true_positives + false_negatives);
  end 

  F1 = 0; 
  if ( (precision + recall) > 0) 
    F1 = 2 * precision * recall / (precision + recall);
  end
 
  if (verbose) 
    ['|--> accuracy == ' num2str(accuracy)] 
    ['|--> F1 == ' num2str(F1)]  
    ['|--> kappa == ' num2str(kappa)] 
    %printf("|-->  true_positives == %i  (actual positive =%i) \n",true_positives,actual_positives);
    %printf("|-->  false_positives == %i \n",false_positives);
    %printf("|-->  false_negatives == %i \n",false_negatives);
    %printf("|-->  precision == %f \n",precision);
    %printf("|-->  recall == %f \n",recall);
    %printf("|-->  F1 == %f \n",F1);
    %printf("|-->  kappa = %f \n",kappa);
  end 
  
end
