class RenameWardPresenterTokenToAdminToken < ActiveRecord::Migration[8.0]
  def change
    rename_column :wards, :presenter_token_digest, :admin_token_digest
  end
end
