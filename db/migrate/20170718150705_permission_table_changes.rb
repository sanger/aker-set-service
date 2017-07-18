class PermissionTableChanges < ActiveRecord::Migration[5.0]
  def change
  	ActiveRecord::Base.transaction do |t|
      add_column :permissions, :permission_type, :string, null: true
  	  AkerPermissionGem::Permission.all.each do |p|
  	  	[
  	  	  [:r, 'read'], [:w, 'write'], [:x, 'execute']
  	  	].each do |column, new_value|
  	  	  if p.send(column)
  	  	    p.dup.update_attributes!(permission_type: new_value)
  	  	  end
  	  	end
  	  	p.destroy
  	  end
  	end

    change_column :permissions, :permission_type, :string, null: false

  	remove_column :permissions, :r
  	remove_column :permissions, :w
  	remove_column :permissions, :x
  end
end
