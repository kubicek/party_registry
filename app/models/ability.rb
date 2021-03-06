class Ability
  include CanCan::Ability

  def initialize(user)

    can [:read, :update, :application, :cancel_membership], Person, :id => user.id
    if user.status!="regular_member"
      can [:destroy], Person, :id => user.id
    end

    can [:jwt_token], Person do |person|
      person.id==user.id && user.is_regular?
    end
    can :read, [Body, Branch, Region, Role]

    can :read, Contact, privacy: 'public'
    can [:create, :update, :destroy], Contact, {contactable_id: user.id, contactable_type: 'Person'}
#    user ||= User.new # guest user (not logged in)

    user.roles.each do |role|
      if role.type == "Coordinator"
        # Koordinátor pobočky
        can [:read, :application, :export], Person, guest_branch_id: role.branch_id
        can [:read, :application, :export], Person, domestic_branch_id: role.branch_id
        can [:supervise], Branch, id: role.branch_id
      elsif (role.type == "President" || role.type == "Vicepresident") && role.body.organization.type=="Region"
        # Členové krajského předsednictva
        can [:read, :application, :export, :update, :approve], Person, domestic_region_id: role.body.organization_id
        can [:read, :application, :export], Person, guest_region_id: role.body.organization_id
        can [:create, :supervise], Branch, parent_id: role.body.organization_id
        can [:supervise], Region, id: role.body.organization_id
        can [:create, :destroy], Role do |r|
          role.body.organization.branch_ids.member?(r.branch_id)
        end
        #can :manage, :all
      elsif role.body.try(:id)==1
        can [:supervise], Region
        can [:supervise], Branch
        can [:read, :application, :export], Person
      elsif role.body.try(:organization).try(:type)=="Country"
        # Členové republikového předsednictva, RK, VK, KK
        can [:read], Person
      end
    end

    if user.is_regular_member?
      can :read, Contact, privacy: ['members','supporters']
    elsif user.is_regular_supporter?
      can :read, Contact, privacy: 'supporters'
    else
      can :read, Contact, privacy: 'public'
    end

    if ([342, 344, 4039, 2804].member?(user.id) || user.roles.detect{|r| r.body_id==1})
      can [:read, :application], Person
      can :upload, SignedApplication
      can [:create, :destroy], Role
      can :create, Branch
      #can :manage, :all
      can :backoffice, :all
    end

    if [342].member?(user.id)
      can :manage, Doorkeeper::Application
    end

  end
end
