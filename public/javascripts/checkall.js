function toggleChecks(field)
{
  check_choice = $('#master_checker')[0].checked
  for (i = 0; i < field.length; i++)
    field[i].checked = check_choice;
}
