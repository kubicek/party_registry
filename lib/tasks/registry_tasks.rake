namespace :registry do
  desc "Imports new data into current db"
  task :import => :environment do
  	sh 'curl --request POST -d "district=0&key='+configatron.old_web.sync_pass+'" https://openid.svobodni.cz/TotalExport.ashx > data/last_export.xml'
  	sh 'rails r import.rb'
  end

  desc "Updates branch members"
  task :update_branches => :environment do
    PaperTrail.whodunnit = 'Branch sorter'
    Person.includes(:domestic_ruian_address, :domestic_branch).all.each{|p|
      if locator = BranchLocator.find_by_person(p)
        if p.domestic_branch.try(:name) != locator.try(:name)
          p.update_attribute :domestic_branch, locator.branch
        end
      end
    }
  end

  desc "Imports from FIO"
  task :import_fio => :environment do
    FioAPI.token=Region.find_by_name("Praha").fio_token
    f=FioAPI::List.new
    #f.set_last_fetch_date "2013-01-01"
    FioPayment.import
  end

end
