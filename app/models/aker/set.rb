class Aker::Set < ApplicationRecord

  has_many :set_materials, foreign_key: :aker_set_id, dependent: :destroy
  has_many :materials, through: :set_materials, source: :aker_material

  has_many :set_transactions, foreign_key: :aker_set_id, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates_format_of :name, with: /\A[a-zA-Z0-9 :'_-]+\z/, message: 'must only contain letters, numbers, spaces, dashes, underscores, colons and apostrophes'

  validate :validate_locked, if: :locked_was

  before_save :sanitise_name, :sanitise_owner
  before_validation :sanitise_name, :sanitise_owner

  # Sets which have Materials in
  scope :inhabited, -> { joins(:set_materials).distinct }

  # Sets which have no Materials in
  scope :empty, -> { left_outer_joins(:set_materials).where( aker_set_materials: { aker_material_id: nil }) }

  def validate_locked
    errors.add(:base, 'Set is locked') unless changes.empty?
  end

  def clone(newname, owner_email)
    copy = Aker::Set.create!(name: newname, locked: false, owner_id: owner_email)
    material_ids = materials.map(&:id)
    bulk_insert!(copy, material_ids)
    copy
  end

  def permitted?(username, access)
    (access.to_sym==:read || owner_id.nil? || (username.is_a?(String) ? owner_id==username : username.include?(owner_id) ))
  end

  def sanitise_name
    if name
      sanitised = name.strip.gsub(/\s+/,' ')
      if sanitised != name
        self.name = sanitised
      end
    end
  end

  def sanitise_owner
    if owner_id
      sanitised = owner_id.strip.downcase
      if sanitised != owner_id
        self.owner_id = sanitised
      end
    end
  end

  # bulk_insert class method comes from the "BulkInsert" gem
  # https://github.com/jamis/bulk_insert#usage
  def bulk_insert!(aker_set, material_ids)
    set_material_attrs = material_ids.map do |material_id|
      { aker_set_id: aker_set.id, aker_material_id: material_id }
    end
    Aker::SetMaterial.bulk_insert(values: set_material_attrs)
  end
end
