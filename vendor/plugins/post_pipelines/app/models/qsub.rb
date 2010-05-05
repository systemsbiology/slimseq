class Qsub 
  attr_accessor :label, :working_dir, :cmd, :cmd_output, :hold, :job_id, :opts, :user, :success, :notify_parent, :ppid
  @@qsub='/sge/bin/lx24-amd64/qsub'
  @@qrls='/sge/bin/lx24-amd64/qrls'

  def launch
    filename=write_file
    cmd="#{@@qsub}"
    cmd+=" -h" if hold
    cmd+=" #{filename}"
    cmd+=" >#{cmd_output_file}"
    puts "cmd: #{cmd}"
    self.success=system cmd

    # store and (maybe) parse command output:
    self.cmd_output=''
    File.open(cmd_output_file).each do |l|
      self.cmd_output+=l
    end
    if (success) 
#       Your job 24349 ("sample_490_fcls_585") has been submitted
      self.job_id=cmd_output.match(/Your job (\d+)/)[1].to_i
    end

    success
  end

  def initialize
    self.opts={}
  end

  # allow inits with a hash:
  def init(hash)
    hash.each_pair do |k,v|
      send("#{k}=",v)
    end
    self
  end

  def set_opt(k,v)
    self.opts[k]=v
  end
  def get_opt(k)
    self.opts[k]
  end

  # derive some opts from regular attrs:
  def derive_opts
    self.opts['N']=label
    self.opts['m']='bea'
    self.opts['o']="#{working_dir}/#{label}.out"
    self.opts['e']="#{working_dir}/#{label}.err"
    self.opts['P']=user
  end

  def write_file
    filename=File.join(working_dir,"#{label}.qsub")
    derive_opts
    File.open(filename,"w") do |f|
      f.puts "\#!/bin/sh"
      opts.each_pair do |k,v| 
        f.puts "\#\$ -#{k} #{v}"
      end
      f.puts
      f.puts cmd
      
      if self.notify_parent
        f.puts "kill -s SIGUSR1 #{@ppid}" 
      end
    end
    filename
  end

  def cmd_output_file
    File.join(working_dir,"#{label}.qsub.out")
  end

  def release
    raise "can't release qsub w/o job_id" if self.job_id.nil?
    cmd="#{@@qrls} #{job_id}"
    system cmd
  end
end
