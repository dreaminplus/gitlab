# frozen_string_literal: true

require "spec_helper"

describe "Admin views license" do
  let_it_be(:admin) { create(:admin) }

  before do
    stub_feature_flags(licenses_app: false)
    sign_in(admin)
  end

  context "when license is valid" do
    before do
      visit(admin_license_path)
    end

    it "shows license" do
      expect(page).to have_content("Your license is valid")

      page.within(".license-panel") do
        expect(page).to have_content("Unlimited")
      end
    end
  end

  context "when license is regular" do
    let_it_be(:license) { create(:license) }

    before do
      visit(admin_license_path)
    end

    context "when license expired" do
      let_it_be(:license) { build(:license, data: build(:gitlab_license, expires_at: Date.yesterday).export).save(validate: false) }

      it { expect(page).to have_content("Your subscription expired!") }

      context "when license blocks changes" do
        let_it_be(:license) { build(:license, data: build(:gitlab_license, expires_at: Date.yesterday, block_changes_at: Date.today).export).save(validate: false) }

        it { expect(page).to have_content "You didn't renew your Starter subscription so it was downgraded to the GitLab Core Plan" }
      end
    end

    context "when viewing license history" do
      let_it_be(:license) { create(:license) }

      it "shows licensee" do
        license_history = page.find("#license_history")

        License.previous.each do |license|
          expect(license_history).to have_content(license.licensee.each_value.first)
        end
      end
    end
  end

  context "with limited users" do
    let_it_be(:license) { create(:license, data: build(:gitlab_license, restrictions: { active_user_count: 2000 }).export) }

    before do
      visit(admin_license_path)
    end

    it "shows panel counts" do
      page.within(".license-panel") do
        expect(page).to have_content("2,000")
      end
    end
  end
end
