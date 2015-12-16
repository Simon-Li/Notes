##################################################################################################################
# Filter out media guids from mrss_freezing table
##################################################################################################################
result = []
ss = SharedState.find_all_by_aggregate_type_and_aggregate_id('mrss_freezing', 0)
ss.each { |e| 
  result << { 
    'title' => e.data['mrss_data_from_adi']['TitleBrief'], 
    'guid1' => e.data['media_guids'][0],
    'guid2' => e.data['media_guids'][1],
  }
}

# IF dump out for importing to Excel
ss = SharedState.find_all_by_aggregate_type_and_aggregate_id('mrss_freezing', 0)
ss.each { |e| 
  puts "title = #{e.data['mrss_data_from_adi']['TitleBrief']} = guid1 = #{e.data['media_guids'][0]} = guid2 = #{e.data['media_guids'][1]}"
}

##################################################################################################################
# get mw_endpoint
##################################################################################################################
def get_mw_endpoint
  ret = SharedState.find_all_by_aggregate_type("Config_Hosts_List").select{|d| d if d.data[:IAS_Service_Name] == "mw"}
  host = ret[0].data[:FQDN]
  service_url = ret[0].data[:IAS_Service_Endpoint]
  t = "http://#{host}#{service_url}"
  log "obtain mw_endpoint #{t}"
  return t
end

###########################################################################################
# To invoke a workorder by http request
###########################################################################################

GET http://<IP>/aspera/orchestrator/work_orders/createBasic/0?work_order[workflow_id]=250&work_order[priority]=2&work_order[name]=hello world&external_parameters[adi_fn]=ffffffffffffffffffffffffffffffffffffffffffffff&commit=Start

Param fields:
work_order[workflow_id]
work_order[priority]
work_order[name]
external_parameters[adi_fn]
commit

###########################################################################################
# insert item into a queue
###########################################################################################
queue_name="Image_Queue"

image_name = "La_famille_Berenstain_E07_E07_DDDE0000005158541306_POSTER_v1_0.jpg"
image_path = "/mnt/mvl/Register/aspera/byDeluxeAuto/#{image_name}"

 
ManagedQueue.queue(queue_name, image_name, image_path)
ManagedQueue.find_by_name_and_queued_item(queue_name, image_name.to_yaml)


###########################################################################################
# find all the complete workorders's offer id which is returned 'true' in "Skip expired" 
# step and "IAS BO Process Each Update" workflow(workflow_id = 228).
###########################################################################################

wo228 = WorkOrder.find(:all, :conditions=>"status = 'Complete' AND workflow_id = 228")

result = []

wo228.each { |a|
  step_id = WorkStep.find_all_by_workOrder_id(a[:id]).select{|e| e[:workStepName] == "Skip expired"}[0][:id]
  filter_result_var_id = WorkOutput.find_all_by_workStep_id(step_id).select{|e| e[:name] == "FilterResult"}[0][:variable_id]

  if Variable.find(filter_result_var_id)[:value_flag] == true  
    wo_inputs = WorkInput.find_all_by_workOrder_id(a[:id])
    offer_var_id = wo_inputs.select{|e| e["name"] == "add_to_url"}.map{|e| {"variable_id"=>e.variable_id}}[0]["variable_id"]
    offer_val = Variable.find(offer_var_id)[:value_string]
    result << { "offer_id"=> offer_val, "filter result"=> true } if Variable.find(filter_result_var_id)[:value_flag] == true
  end
}


##################################################################################
# Change specific SharedState table field
##################################################################################
ss = SharedState.find_all_by_aggregate_type("Rights_Rights_List")
ss.each { |e|
  e.data[:NGVTrickplay][2]["value"] = "Pause"
  e.save
}

ss = SharedState.find_all_by_aggregate_type("Offers_Offers_List")
ss.each { |e|
  e.data[:NGVTrickplay][2]["value"] = "Pause" if !e.data[:NGVTrickplay].nil?
  e.save
}

##################################################################################

life = SharedState.find_all_by_aggregate_type("IAS_MAIN_LIFECYCLE", :order=>["updated_at desc"]).map{|a| 
  {
    "created_at"=> a.created_at,
    "updated_at"=> a.updated_at,
    "adi"=>a.data[:adi],
    "media_cage_dir" => a.data[:media_cage_dir],
    "aggregate_id" => a.aggregate_id
  }
}

life[0]["adi"].split('/')[-1].split("_METADATA")[0].split("_").reverse.drop(1).reverse.join("_")

life.select{|a| (a["aggregate_id"] < 8)}.size

stateless8 = life.select{|a| (a["aggregate_id"] < 8)}


freezing = SharedState.find_all_by_aggregate_type("ADI_MAIN_FREEZING", :order=>["created_at asc"]).map{|a|
{
"created_at" => a.created_at,
"updated_at" => a.updated_at,
"aggregate_id" => a.aggregate_id,
"is_exception" => a.data["is_exception_in_unfreeze"],
"xml_name" => a.data["xml"],
"ss_id" => a.id,
"exception_id" => a.data["exception_id"]
}
}


complete = SharedState.find_all_by_aggregate_type("IAS_MAIN_LIFECYCLE_ARCHIVE", :order=>["updated_at desc"]).map{|a|
  {
    "created_at"=> a.created_at,
    "updated_at"=> a.updated_at,
    "adi"=>a.data[:adi],
    "media_cage_dir" => a.data[:media_cage_dir],
    "aggregate_id" => a.aggregate_id
  }
}

complete.size
complete[0]["adi"].split('/')[-1].split("_METADATA")[0].split("_").reverse.drop(1).reverse.join("_")


########## Script starts ###########
begin

life_adis = SharedState.find_all_by_aggregate_type("IAS_MAIN_LIFECYCLE", :order=>["updated_at desc"]).map{|a| 
  {
    "created_at"=> a.created_at,
    "updated_at"=> a.updated_at,
    "adi"=>a.data[:adi],
    "media_cage_dir" => a.data[:media_cage_dir],
    "aggregate_id" => a.aggregate_id
  }
}

complete_adis = SharedState.find_all_by_aggregate_type("IAS_MAIN_LIFECYCLE_ARCHIVE", :order=>["updated_at desc"]).map{|a|
  {
    "created_at"=> a.created_at,
    "updated_at"=> a.updated_at,
    "adi"=>a.data[:adi],
    "media_cage_dir" => a.data[:media_cage_dir],
    "aggregate_id" => a.aggregate_id
  }
}

complete_titles = []
complete_adis.each{ |a| 
  complete_titles << a["adi"].split('/')[-1].split("_METADATA")[0].split("_").reverse.drop(1).reverse.join("_")
}

puts complete_titles 
puts complete_titles.size

matched_titles = []
life_adis.each { |a|
  life_title = a["adi"].split('/')[-1].split("_METADATA")[0].split("_").reverse.drop(1).reverse.join("_")
  if complete_titles.include? life_title
    matched_titles << { "short"=>life_title, "full"=>a["adi"].split('/')[-1] }
  end
}

puts 'found matched titles:'
pp matched_titles

report = []
matched_titles.each { |title|
  ret = WorkOrder.find(:all, :conditions=>"name LIKE '%#{title["full"]}%' AND workflow_id = 195")
  found = ret.map{ |e|
    {"wo_id"=>e.id, "match_title"=>title["full"], "name"=>e.name, "status"=>e.status}
  }
  pp found
  report << found
}

puts 'report:'
report.size
end
########## Script end ###########


title = "No_Country_for_Old_Men"
resl = WorkOrder.find(:all, :conditions=>"name LIKE '%#{title}%'")

resl.map{|e| {"wo_id"=>e.id, "wf_id"=>e.workflow_id, "wf_name"=>e.workflowName}}
resl.map!{|e| {"wo_id"=>e.id, "wf_id"=>e.workflow_id, "wf_name"=>e.workflowName}}


resl.select {|a| a["wf_id"]== 195}
=> [{"wf_id"=>195, "wo_id"=>6921842, "wf_name"=>"Main - ADI info and MW"}, {"wf_id"=>195, "wo_id"=>8230893, "wf_name"=>"Main - ADI info and MW"}]

resl.select {|a| a["wo_id"]== 8230893}
=> [{"wf_id"=>195, "wo_id"=>8230893, "wf_name"=>"Main - ADI info and MW"}]


begin
title = "No_Country_for_Old_Men"
start_t = Time.now
res = WorkOrder.find(:all, :conditions=>"name LIKE '%#{title}%' AND workflow_id = 195")
end_t = Time.now
end_t - start_t
res.map{ |e|
  {"wo_id"=>e.id, "name"=>e.name, "wf_id"=>e.workflow_id, "status"=>e.status}
}
end
res


begin
title = "No_Country_for_Old_Men_HWST1511171038005702_METADATA_v1_0.xml"
t_start = Time.now
resl = WorkOrder.find(:all, :conditions=>"name = '#{title}'")
t_end = Time.now
pp resl
t_end - t_start
end


########## Script starts ver 0.1 ###########
begin

life_adis = SharedState.find_all_by_aggregate_type("IAS_MAIN_LIFECYCLE", :order=>["updated_at desc"]).map{|a| 
  {
    "adi"=>a.data[:adi],
  }
}

complete_adis = SharedState.find_all_by_aggregate_type("IAS_MAIN_LIFECYCLE_ARCHIVE", :order=>["updated_at desc"]).map{|a|
  {
    "adi"=>a.data[:adi],
  }
}

complete_titles = []
complete_adis.each{ |a| 
  complete_titles << a["adi"].split('/')[-1].split("_METADATA")[0].split("_").reverse.drop(1).reverse.join("_")
}

puts complete_titles 
puts complete_titles.size

matched_titles = []
life_adis.each { |a|
  life_title = a["adi"].split('/')[-1].split("_METADATA")[0].split("_").reverse.drop(1).reverse.join("_")
  if complete_titles.include? life_title
    matched_titles << { "short"=>life_title, "full"=>a["adi"].split('/')[-1] }
  end
}

=begin

puts 'Processing matched short titles:'

report = []
inprogressAry = []
failedAry = []
failed = 0
flagged = 0
completed = 0
cleared = 0
inprogress = 0

matched_titles.each { |title|
  ret = WorkOrder.find(:all, :conditions=>"name LIKE '%#{title["short"]}%' AND workflow_id = 195")
  ret.map{ |e|
    found = {"wo_id"=>e.id, "match_title"=>title["full"], "name"=>e.name, "status"=>e.status}
    case e.status
    when "Failed"
      failed=failed+1
      failedAry << found
    when "Flagged"
      flagged=flagged+1
    when "Complete"
      completed=completed+1
    when "Cleared"
      cleared=cleared+1
    when "In Progress"
      inprogress=inprogress+1
      inprogressAry << found
    end

    report << found
  } 
}
=end


puts 'Processing exactly matched titles:'

report = []
inprogressAry = []
failedAry = []
failed = 0
flagged = 0
completed = 0
cleared = 0
inprogress = 0

matched_titles.each { |title|
  ret = WorkOrder.find(:all, :conditions=>"name LIKE '%#{title["full"]}%' AND workflow_id = 195")
  ret.map{ |e|
    found = {"wo_id"=>e.id, "match_title"=>title["full"], "name"=>e.name, "status"=>e.status}
    case e.status
    when "Failed"
      failed=failed+1
      failedAry << found
    when "Flagged"
      flagged=flagged+1
    when "Complete"
      completed=completed+1
    when "Cleared"
      cleared=cleared+1
    when "In Progress"
      inprogress=inprogress+1
      inprogressAry << found
    end

    report << found
  }
}


puts 'report size:', report.size
puts 'failed:', failed
puts 'flagged:', flagged
puts 'completed:', completed
puts 'cleared:', cleared
puts 'inprogress:', inprogress
puts 'found report:'
pp report
pp inprogressAry
pp failedAry
end
########## Script end ###########

###############################################################

Destroy work order:
POST /aspera/orchestrator/work_orders/destroy/8277450 HTTP/1.1
Host: 10.222.9.113

Cancel work order:
POST /aspera/orchestrator/work_orders/cancel/8274227 HTTP/1.1
Host: 10.222.9.113

###############################################################

# search/match in IAS_MAIN_LIFECYCLE, IAS_MAIN_LIFECYCLE_ARCHIVE

title = "The_Big_Bang_Theory_S09E09_S09E09_CTHD9232010000000002_METADATA_v1_0.xml"

life = SharedState.find_all_by_aggregate_type("IAS_MAIN_LIFECYCLE", :order=>["updated_at desc"])

resl = life.select{ |e|
  e.data[:adi].split('/')[-1] == title
}

life = SharedState.find_all_by_aggregate_type("IAS_MAIN_LIFECYCLE", :order=>["updated_at desc"])

resl = life.select{ |e|
  e.data[:adi].split('/')[-1].include? title
}

complete = SharedState.find_all_by_aggregate_type("IAS_MAIN_LIFECYCLE_ARCHIVE", :order=>["updated_at desc"])

resl = complete.select{ |e|
  e.data[:adi].split('/')[-1].include? title
}

complete = SharedState.find_all_by_aggregate_type("IAS_MAIN_LIFECYCLE_ARCHIVE", :order=>["updated_at desc"]).map{|a|
  {
    "adi"=>a.data[:adi],
  }
}

res = complete.select{ |e|
  e["adi"].split('/')[-1] == title
}

resl.each { |e| e.destroy }

##################################################################

ManagedQueue

ManagedQueue.find_by_name("Video_Queue")

# fine queue item by item id
ManagedQueue.find(2008469)



SharedState.find_all_by_aggregate_type("ADI_MAIN_FREEZING", :order=>["created_at asc"])

SharedState.find_all_by_aggregate_type("ADI_MAIN_FREEZING", :order=>["created_at asc"]).select{|e| e[:name]=="Easy_Money_HWST1510231346013802_METADATA_v1_0.xml"}

=============================================================================



ss = WorkOrder.find(:all, :conditions=>"status = 'In Progress'")
res = ss.map{ |e| {"name"=>e.name, "workorder_id"=>e.id, "workorder_details"=>e.statusDetails, "created_at"=>e.created_at, "updated_at"=>e.updated_at, "wf_name"=>e.workflowName} }.select{|e| e["wf_name"] == "SL_Main"}

out = res.each { |a|
  step_id = WorkStep.find_by_workOrder_id(a["workorder_id"])[:id]
  a["workstep_details"] = WorkStep.find(step_id)[:statusDetails]
}

=========================================================================

# get the DIAS ID for In-progress workorders, preferrable solution to get into the worksteps and pick up whatever in/out params value

ss = WorkOrder.find(:all, :conditions=>"status = 'In Progress'")
wf183 = ss.select{|e| e["workflow_id"] == 183}    # SL Process Publish

result = []

wf183.each {|a|
  step_id = WorkStep.find_all_by_workOrder_id(a[:id]).select{|e| e[:workStepName] == "DCenter Lite"}[0][:id]
  #WorkInput.find_all_by_workStep_id(step_id)
  var_id = WorkOutput.find_all_by_workStep_id(step_id).select{|e| e[:name] == "xco_dcenter_array"}[0][:variable_id]
  result << { "title"=>a[:name], "dias"=> Variable.find(var_id)[:value_string] }
}

=========================================================================

# get the DIAS ID for In-progress workorders

ss = WorkOrder.find(:all, :conditions=>"status = 'In Progress'")
wf183 = ss.select{|e| e["workflow_id"] == 183}

result = []

wf183.each {|a|
  wo_inputs = WorkInput.find_all_by_workOrder_id(a[:id])
  var_id = wo_inputs.select{|e| e["name"] == "xco_dcenter_array"}.map{|e| {"variable_id"=>e.variable_id}}[0]["variable_id"]
  result << { "name"=>a[:name], "dias"=>Variable.find(var_id)[:value_string] }
}

=========================================================================

# by workstep id
WorkStep.find(193319)  

# by workorder id
WorkStep.find_by_workOrder_id(21316)

# by workorder id
WorkStep.find_all_by_workOrder_id(workorderId)

# by workorder id
WorkInput.find_all_by_workStep_id(workStepId)

# by workstep id
WorkOutput.find_all_by_workStep_id(193319)

# by workstep id
varResl = Variable.find(:all,:conditions=>["workStep_id=193319"])

# by variable id
Variable.find(633876)

# get 'value_string' value out of the variable for the workstep input
Variable.find(633876)[:value_string]

# by variable id
Variable.find(634158)

actives = ActiveAssignment.find(:all,:conditions=>["status = ? and exists(select 1 from work_steps as W where W.id=state_id and W.status=?)", ActiveAssignment::STATUS_ASSIGNED, Action::STATUS_INPROGRESS], :order=>"created_at")

# by active assignment id
ActiveAssignment.find(90337)

?> ActiveAssignment.find(90336)
=> #<ActiveAssignment id: 90336, state_id: 84819363, userInput_id: 55, role_id: 7, user_id: nil, status: "Complete", completedBy: 49, created_at: "2015-11-25 18:30:12", updated_at: "2015-11-25 18:33:57">
>> ActiveAssignment.find(90337)
=> #<ActiveAssignment id: 90337, state_id: 84893027, userInput_id: 50, role_id: 1, user_id: nil, status: "Assigned", completedBy: nil, created_at: "2015-11-25 20:48:32", updated_at: "2015-11-25 20:48:32">

# list all "Assigned" active assignments
ActiveAssignment.find_all_by_status("Assigned")

=============================================================================

Create work order at app/controllers/work_orders_controller.rb
  def createBasic(inline=false)
  end

=============================================================================














