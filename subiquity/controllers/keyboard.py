# Copyright 2015 Canonical, Ltd.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import logging

from subiquitycore.controller import BaseController

from subiquity.models.keyboard import KeyboardSetting
from subiquity.ui.views import KeyboardView

log = logging.getLogger('subiquity.controllers.keyboard')


class KeyboardController(BaseController):

    signals = [
        ('l10n:language-selected', 'language_selected'),
        ]

    def __init__(self, common):
        super().__init__(common)
        self.model = self.base_model.keyboard
        self.answers = self.all_answers.get("Keyboard", {})

    def language_selected(self, code):
        log.debug("language_selected %s", code)
        if not self.model.has_language(code):
            code = code.split('_')[0]
        if not self.model.has_language(code):
            code = 'C'
        log.debug("loading language %s", code)
        self.model.load_language(code)

    def default(self):
        if self.model.current_lang is None:
            self.model.load_language('C')
        view = KeyboardView(self.model, self, self.opts)
        self.ui.set_body(view)
        if 'layout' in self.answers:
            layout = self.answers['layout']
            variant = self.answers.get('variant', '')
            self.done(KeyboardSetting(layout=layout, variant=variant))

    def done(self, setting):
        self.run_in_bg(
            lambda: self.model.set_keyboard(setting),
            self._done)

    def _done(self, fut):
        log.debug("KeyboardController._done next-screen")
        self.signal.emit_signal('next-screen')

    def cancel(self):
        self.signal.emit_signal('prev-screen')
