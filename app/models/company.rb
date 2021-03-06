# == Schema Information
#
# Table name: namespaces
#
#  id               :integer          not null, primary key
#  name             :string
#  description      :string
#  owner_id         :integer
#  owner_type       :string
#  type             :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  visibility_level :integer
#
# Indexes
#
#  index_namespaces_on_name                     (name) UNIQUE
#  index_namespaces_on_owner_type_and_owner_id  (owner_type,owner_id)
#  index_namespaces_on_type                     (type)
#  index_namespaces_on_visibility_level         (visibility_level)
#

class Company < Namespace
  belongs_to :owner, polymorphic: true
  # TODO: Add some sort of verification here
  # Did user work @ company?
end
