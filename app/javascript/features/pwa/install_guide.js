export function mountInstallGuide(controller) {
  if (!controller.hasGuideTemplateTarget || !controller.hasDialogTarget || controller.hasSheetTarget) return
  controller.dialogTarget.append(controller.guideTemplateTarget.content.cloneNode(true))
  controller.guideTemplateTarget.remove()
}

export function resetInstallGuide(controller) {
  controller.dialogTarget.scrollTop = 0
  window.requestAnimationFrame(() => {
    controller.dialogTarget.scrollTop = 0
    if (controller.hasSheetTarget) controller.sheetTarget.focus({ preventScroll: true })
  })
}
