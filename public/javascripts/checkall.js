function checkAll(field)
{
for (i = 0; i < field.length; i++)
  field[i].checked = true ;
}

function uncheckAll(field)
{
  for (i = 0; i < field.length; i++)
    field[i].checked = false ;
}
function toggleChecks(field)
{
  check_choice = $('master_checker').checked
  for (i = 0; i < field.length; i++)
    field[i].checked = check_choice;
}
