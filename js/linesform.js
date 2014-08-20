
function init_form() 
{
      if((form_step==1)||(form_step==2))
      {
		  var rd = document.lineform.elements[0];
		  if(rd.type=="radio")
		  {      
	       	rd.checked = true;
	      }
      }
      if(form_step==3)
      {
       var actual_date  = new Date();
       
	   var begin_year = 2020;
	   i = begin_year-actual_date.getFullYear();
	   document.lineform.year[i].selected = true;
	   
	   i = actual_date.getMonth();
	   document.lineform.month[i].selected = true;
	   
	   i = actual_date.getDate()-1;
	   document.lineform.day[i].selected = true;
      }
	 
}

function check_form()
{ 
   if(form_step==3)
   {
	   // Check line type
	   var actual_date  = new Date();
	   var today_date  = new Date();
	
	   actual_date.setFullYear(document.lineform.year[document.lineform.year.selectedIndex].value);
	   actual_date.setMonth(document.lineform.month[document.lineform.month.selectedIndex].value - 1);
	   actual_date.setDate(document.lineform.day[document.lineform.day.selectedIndex].value);
	   
	   for(i=0; i<(document.lineform.length); i++)
	   {
		  var tt = document.lineform.elements[i];
		  if(tt.name=="linetype")
		  {
		  	if(tt.checked)
		  	{
		  		typeval=tt.value;
			}      
	      }
	   }
	   
	   if(actual_date.getTime() <= today_date.getTime() )
	   {
	    if(typeval==0)
	    {
	   		if(actual_date.getTime() == today_date.getTime() )
	   		{
	    		alert("Это сегодняшняя дата. Выберите другой тип отсчёта.");
	    	}
	    	else
	    	{	
	    		alert("Дата уже прошла");
	    	}
	    	return false;
		}	
	   }   
	   if(actual_date.getTime() > today_date.getTime() )
	   {
	    if(typeval==1)
	    {
	    	alert("Дата ещё не наступила");
	    	return false;
		}	
	   }   
   }
	
   document.lineform.submit();
}

function manual_set()
{
  for(i=0; i<(document.lineform.length); i++)
  {
      var rd = document.lineform.elements[i];
      if(rd.value=="manual")
      {
      	rd.checked = true;
	  }
  }
}	
